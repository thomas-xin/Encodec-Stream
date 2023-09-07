# Encodec-Stream
A somewhat lightweight wrapper around [Encodec](https://github.com/facebookresearch/encodec) that enables dynamic streamed reading, seeking, metadata and GPU support.

## Problem
By nature, the ECDC format was originally intended to be encoded and decoded in a single step. This makes it efficient, but makes streaming incredibly difficult.
This program attempts to mitigate the issues associated with the format:
- The encoded audio is split into segments, each of which may be decoded separately, but must be decoded together in normal operation, else the audio stutters in between.
- Decoding two segments in one steps connects them, however the second segment will still stutter when transitioning into the third.
- Decoding three causes the same issue with the fourth, and so on, meaning there is no way to perfectly decode and stream audio without re-decoding some segments more than once.
- A possible solution is to decode windows of three segments at a time, only outputting the central one at any given time. This would function as a working stream, however introduces a +200% computational overhead due to needing to process three times the data.
- The proposed solution used in this program 

## Usage
```
Usage (arguments in parentheses are optional):
Get ECDC info: ecdc_stream.py -i <file-or-url>
Decode ECDC->PCM: ecdc_stream.py (-ss <seek-start> -to <seek-end> -g <cuda-device>) -d <file-or-url>
Encode PCM->ECDC: ecdc_stream.py (-b <bitrate> -n <song-name> -s <source-url> -g <cuda-device>) -e <file>
```

- The program takes streamed inputs and outputs as PCM via stdin and stdout respectively, making it easy to integrate as a subprocess.
- This is similar to, and intentionally designed to be compatible with `ffmpeg -f s16le -ac 2 -ar 48k (-i) -` and similar programs.
- A simple use case for playing a .ecdc file without needing to process all data would be `py ecdc_stream.py <ecdc_file> | ffplay -f s16le -ac 2 -ar 48k -i -`.
- Encoding any song to .ecdc can be done via `ffmpeg -i <song> -f s16le -ac 2 -ar 48k - | py ecdc_stream.py -b <bitrate> -e <file>`.
- If not specified, the cuda-device automatically takes a random GPU if possible, falling back to CPU inference otherwise.
