# Encodec-Stream
A somewhat lightweight wrapper around [Encodec](https://github.com/facebookresearch/encodec) that enables dynamic streamed reading, seeking, metadata and GPU support.

## Problem
By nature, the ECDC format was originally intended to be encoded and decoded in a single step. This makes it efficient, but makes streaming incredibly difficult.
This program attempts to mitigate the issues associated with the format:
- The encoded audio is split into segments, each of which may be decoded separately, but must be decoded together in normal operation, else the audio stutters in between.
- For instance, decoding two segments in one steps connects them, however the second segment will still stutter when transitioning into the third.
- Decoding three causes the same issue with the fourth, and so on, meaning there is no way to perfectly decode and stream audio without re-decoding some segments more than once.
- A possible solution is to decode windows of three segments at a time, only outputting the central one at any given time. This would function as a working stream, however introduces a +200% computational overhead due to needing to process three times the data. This is a big deal as encodec is already significantly more computationally expensive than any other standard audio format.
- The proposed solution used in this program is to process the audio in increasing window sizes;
  - the first iteration will process the first two segments in order to return the first;
  - the second iteration will process the first to fourth segments in order to return the second and third;
  - the third iteration will process the third to seventh segments in order to return the fourth to sixth, and so on.
  - This enables the first segment to be streamed as soon as possible, seamlessly blending into the subsequent segments, and the increasing window size allows overhead to be reduced as decoding continues.


Example GPU usage trend during decoding (note the linearly increasing gap between each window):
![GPU usage trend during decoding](https://mizabot.xyz/u/EOVY6jGAAII.png)

## Usage
- Python must first be installed.
- Encodec must be installed (`pip install git+https://github.com/facebookresearch/encodec`).
- FFmpeg or a similar PCM-handling framework should be installed for best results (https://ffmpeg.org).
```
Usage (arguments in parentheses are optional):
Get ECDC info: ecdc_stream.py -i <file-or-url>
Decode ECDC->PCM: ecdc_stream.py (-ss <seek-start> -to <seek-end> -b <buffer-size> -g <cuda-device>) -d <file-or-url>
Encode PCM->ECDC: ecdc_stream.py (-b <bitrate> -n <song-name> -s <source-url> -g <cuda-device>) -e <file>
```

- The program takes streamed inputs and outputs as PCM via stdin and stdout respectively, making it easy to integrate as a subprocess.
- This is similar to, and intentionally designed to be compatible with `ffplay -f s16le -ac 2 -ar 48k (-i) -` and similar programs.
- A simple use case for playing a .ecdc file without needing to process all data would be `py ecdc_stream.py -d <ecdc_file> | ffplay -f s16le -ac 2 -ar 48k -i -`.
- Encoding any song to .ecdc can be done via `ffmpeg -i <song> -f s16le -ac 2 -ar 48k - | py ecdc_stream.py -b <bitrate> -e <file>`.
- If not specified, the cuda-device automatically takes a random GPU if possible, falling back to CPU inference otherwise.
- The `-i` "info" mode of the program outputs a yaml-style list as follows (example):
  - Version: 192
  - Duration: 244.3668125
  - Bitrate: 24
  - M: encodec_48khz
  - AL: 11729607
  - NC: 16
  - LM: False
- When decoding (`-d`), the initial window size may be increased by specifying the bufsize (`-b`) parameter. This defaults to 1, which starts with a window size of 1 (lowest latency, `Õ(2n)` time complexity), increasing by 1 each time (amortised constant latency, `Õ(n + 2sqrt(n))` time complexity). A value of 2 would start with a window size of 2 (slightly higher latency, `Õ(3n/2)` time complexity), increasing by 2 each time (`Õ(n + sqrt(n))` time complexity), and so on.
  - A value of 0 may be specified to bypass the windowing completely, which will buffer the entire file before outputting (similar to the original Encodec implementation). This reduces the overhead to 0% or `Õ(n)` immediately, but has the drawback of much higher latency particularly on weaker hardware or longer files. This option is mostly intended to function as a slightly more efficient way to directly decode and convert without needing to stream.

## Hardware Requirements
- A NVIDIA GPU (minimum GTX650) is recommended for both performance and efficiency, however any CPU with ~50 GFLOPS of performance (minimum Ryzen 5 5625U) should be capable of decoding and playing a realtime audio stream.
- 2GB of RAM, or 1GB of RAM and 1GB of VRAM (such as in the GTX650) is more than sufficient for most everyday audio files. The increasing window algorithm has a space complexity of `O(sqrt n)`, meaning memory consumption is not typically a concern with encoding/decoding through Encodec. While running however, the PyTorch libraries may use up to 1GB, hence the conservative estimate.
