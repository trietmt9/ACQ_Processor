#!/usr/bin/env python3
"""
Batch ACQ file converter
Converts multiple BIOPAC ACQ files to JSON metadata and binary channel data.
The JSON file is cumulative - it updates with each new ACQ file processed.
Binary files are separate for each channel of each ACQ file.
"""
import sys
import json
import os
from pathlib import Path
import numpy as np
import bioread
from datetime import datetime


def convert_acq_file(input_file, output_dir, metadata_dict):
    """
    Convert a single ACQ file to binary channel data and update metadata.

    Args:
        input_file: Path to the input .acq file
        output_dir: Directory to save binary files
        metadata_dict: Dictionary to update with this file's metadata

    Returns:
        True if successful, False otherwise
    """
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    print(f"\n{'='*60}")
    print(f"Reading ACQ file: {input_file}")
    print(f"{'='*60}")

    try:
        data = bioread.read_file(input_file)
    except Exception as e:
        print(f"ERROR: Failed to read ACQ file: {e}", file=sys.stderr)
        return False

    # Create a safe filename prefix from the input filename
    base_name = Path(input_file).stem  # filename without extension
    safe_prefix = "".join(c if c.isalnum() or c in ('-', '_') else '_' for c in base_name)

    # Create metadata for this file
    file_metadata = {
        'source_file': os.path.basename(input_file),
        'processed_timestamp': datetime.now().isoformat(),
        'num_channels': len(data.channels),
        'channels': []
    }

    # Process each channel
    for i, channel in enumerate(data.channels):
        try:
            # Validate channel has required attributes
            if channel is None:
                print(f"\nWARNING: Channel {i} is None, skipping", file=sys.stderr)
                continue

            if channel.data is None:
                print(f"\nWARNING: Channel {i} has no data, skipping", file=sys.stderr)
                continue

            if channel.samples_per_second is None or channel.samples_per_second <= 0:
                print(f"\nWARNING: Channel {i} has invalid sample rate, skipping", file=sys.stderr)
                continue

            print(f"\nChannel {i}: {channel.name}")
            print(f"  Sample rate: {channel.samples_per_second} Hz")
            print(f"  Samples: {len(channel.data)}")
            print(f"  Units: {channel.units}")
            print(f"  Duration: {len(channel.data) / channel.samples_per_second:.2f} seconds")

            # Calculate statistics
            data_array = np.array(channel.data, dtype=np.float32)
            stats = {
                'min': float(np.min(data_array)),
                'max': float(np.max(data_array)),
                'mean': float(np.mean(data_array)),
                'std': float(np.std(data_array))
            }

            # Create binary filename for this channel
            binary_filename = f"{safe_prefix}_channel_{i}.bin"
            binary_path = output_path / binary_filename

            # Save channel data as binary (float32)
            data_array.tofile(binary_path)
            print(f"  ✓ Saved binary: {binary_filename} ({len(data_array) * 4} bytes)")

            # Add channel metadata
            channel_info = {
                'index': i,
                'name': channel.name,
                'units': channel.units,
                'sample_rate': float(channel.samples_per_second),
                'num_samples': len(channel.data),
                'duration_seconds': len(channel.data) / channel.samples_per_second,
                'binary_file': binary_filename,
                'data_type': 'float32',
                'statistics': stats
            }

            file_metadata['channels'].append(channel_info)

        except (AttributeError, TypeError) as e:
            print(f"\nWARNING: Channel {i} has missing/invalid attributes: {e}", file=sys.stderr)
            print(f"  Skipping this channel", file=sys.stderr)
            continue
        except Exception as e:
            print(f"\nWARNING: Unexpected error processing channel {i}: {e}", file=sys.stderr)
            print(f"  Skipping this channel", file=sys.stderr)
            continue

    # Check if any channels were successfully processed
    if len(file_metadata['channels']) == 0:
        print(f"\nWARNING: No valid channels found in {os.path.basename(input_file)}", file=sys.stderr)
        print(f"  File will be skipped from metadata", file=sys.stderr)
        return False

    # Add this file's metadata to the cumulative dictionary
    metadata_dict['files'].append(file_metadata)
    metadata_dict['total_files_processed'] = len(metadata_dict['files'])
    metadata_dict['last_updated'] = datetime.now().isoformat()

    print(f"\n✓ Successfully processed: {os.path.basename(input_file)} ({len(file_metadata['channels'])} channels)")
    return True


def batch_convert(input_files, output_dir):
    """
    Convert multiple ACQ files, updating a cumulative JSON metadata file.

    Args:
        input_files: List of paths to .acq files
        output_dir: Directory to save outputs

    Returns:
        Number of successfully processed files
    """
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    metadata_file = output_path / 'metadata.json'

    # Load existing metadata if it exists, otherwise create new
    if metadata_file.exists():
        print(f"Loading existing metadata from: {metadata_file}")
        with open(metadata_file, 'r') as f:
            metadata_dict = json.load(f)
    else:
        print("Creating new metadata file")
        metadata_dict = {
            'created': datetime.now().isoformat(),
            'total_files_processed': 0,
            'files': []
        }

    # Process each input file
    success_count = 0
    for input_file in input_files:
        # Validate input file
        if not os.path.exists(input_file):
            print(f"\nWARNING: File not found, skipping: {input_file}", file=sys.stderr)
            continue

        if not input_file.lower().endswith('.acq'):
            print(f"\nWARNING: File does not have .acq extension: {input_file}")

        # Convert file and update metadata
        if convert_acq_file(input_file, output_dir, metadata_dict):
            success_count += 1

            # Save updated metadata after each file (in case of failures)
            try:
                with open(metadata_file, 'w') as f:
                    json.dump(metadata_dict, f, indent=2)
            except Exception as e:
                print(f"ERROR: Failed to save metadata: {e}", file=sys.stderr)

    # Final summary
    print(f"\n{'='*60}")
    print(f"CONVERSION COMPLETE")
    print(f"{'='*60}")
    print(f"Total files processed: {success_count}/{len(input_files)}")
    print(f"Output directory: {output_path.absolute()}")
    print(f"Metadata file: {metadata_file.name}")
    print(f"Total binary files: {sum(len(f['channels']) for f in metadata_dict['files'])}")

    return success_count


def main():
    if len(sys.argv) < 3:
        print("Usage: batch_acq_converter.py <output_directory> <input1.acq> [input2.acq] [input3.acq] ...")
        print()
        print("Description:")
        print("  Converts multiple ACQ files to JSON metadata and binary channel data.")
        print("  The JSON file is cumulative and updates with each new ACQ file.")
        print("  Binary files are saved separately for each channel.")
        print()
        print("Examples:")
        print("  # Convert a single file")
        print("  python batch_acq_converter.py ./output data/sample.acq")
        print()
        print("  # Convert multiple files")
        print("  python batch_acq_converter.py ./output data/file1.acq data/file2.acq data/file3.acq")
        print()
        print("  # Convert all ACQ files in a directory (using shell expansion)")
        print("  python batch_acq_converter.py ./output data/*.acq")
        return 1

    output_dir = sys.argv[1]
    input_files = sys.argv[2:]

    print(f"Output directory: {output_dir}")
    print(f"Input files: {len(input_files)}")

    # Convert files
    success_count = batch_convert(input_files, output_dir)

    if success_count == 0:
        print("\nERROR: No files were successfully processed", file=sys.stderr)
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main())
