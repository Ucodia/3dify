# threedify - a easy to use command line tool to automate photogrammetry

`threedify` creates 3D models from images using photogrammetry.

```
threedify ./input-images ./model.usdz
```

## Requirements

macOS 14.0+

## Installation

Install with [brew](https://brew.sh/):
```
brew install ucodia/tools/threedify
```

## Usage

```
OVERVIEW: Creates 3D models from images using photogrammetry.

USAGE: threedify <input-folder> <output-filename> [--disable-masking] [--detail <detail>] [--checkpoint-directory <checkpoint-directory>] [--sample-ordering <sample-ordering>] [--feature-sensitivity <feature-sensitivity>] [--max-polygons <max-polygons>]

ARGUMENTS:
  <input-folder>          The folder of images.
  <output-filename>       The output filename. If the path is a .usdz file path, the export will generatea a USDZ file, if
                          the path is a directory, it will generate an OBJ in the directory.

OPTIONS:
  --disable-masking       Determines whether or not to disable masking of the scene around the model.
  -d, --detail <detail>   detail {preview, reduced, medium, full, raw, custom}  Detail of output model in terms of mesh size
                          and texture size.
  -c, --checkpoint-directory <checkpoint-directory>
                          Provide a checkoint directory to be able to restart a session which was interrupted.
  -o, --sample-ordering <sample-ordering>
                          sampleOrdering {unordered, sequential}  Setting to sequential may speed up computation if images
                          are captured in a spatially sequential pattern.
  -f, --feature-sensitivity <feature-sensitivity>
                          featureSensitivity {normal, high}  Set to high if the scanned object does not contain a lot of
                          discernible structures, edges or textures.
  -p, --max-polygons <max-polygons>
                          maxPolygons {number} Reducing the maximum number if polygons can help tweak the detail level of
                          detail of the mesh. Only applies to custom detail level.
  -h, --help              Show help information.
```