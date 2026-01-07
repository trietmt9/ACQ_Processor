# ACQ Signal Processor

A Qt6-based desktop application for processing, filtering, and analyzing BIOPAC ACQ physiological data files. This tool provides an intuitive interface for DSP engineers to load ACQ files, apply various filters, and annotate signal segments with custom labels.

## Features

- **ACQ File Loading**: Automatically converts BIOPAC ACQ files to processable format using Python bioread library
- **Signal Visualization**: Real-time waveform plotting with Qt Charts
  - **Time-based X-axis**: Display time in seconds instead of sample indices
  - **Mouse wheel zoom**: Zoom in/out on both time and voltage axes
  - **Interactive selection**: Click and drag to select time ranges
- **DSP Filtering**: Four types of Butterworth IIR filters:
  - Lowpass Filter
  - Highpass Filter
  - Bandpass Filter
  - Notch Filter
- **Signal Labeling**: Annotate waveform segments with custom labels and colors
  - **Toggle labeling mode**: Click "Label" button to show/hide labeling panel
  - **Visual indicators**: Clear indication when labeling mode is active
  - **Color selection**: 9 preset colors for categorizing segments
- **Export Labels**: Save comprehensive label annotations to JSON format including:
  - Time information (start/end times in seconds)
  - Complete voltage data for each segment
  - Statistical analysis (min, max, average voltage)

## Prerequisites

### System Requirements
- C++ compiler with C++17 support (GCC 7+, Clang 5+, MSVC 2017+)
- CMake 3.16 or higher
- Qt 6.2 or higher with the following modules:
  - Qt Core
  - Qt GUI
  - Qt Quick
  - Qt QML
  - Qt Charts

### Python Requirements
- Python 3.7 or higher
- bioread library version 3.1.0 (critical - newer versions may have compatibility issues)

Install bioread:
```bash
pip install bioread==3.1.0
```

Or if using a virtual environment:
```bash
source ~/.pyvenv/bin/activate
pip install bioread==3.1.0
```

## Building the Application

1. Clone or navigate to the project directory:
```bash
cd /path/to/ACQ_Read
```

2. Create a build directory:
```bash
mkdir build
cd build
```

3. Configure with CMake:
```bash
cmake ..
```

4. Build the project:
```bash
cmake --build .
```

5. The executable will be in the build directory:
```bash
./ACQ_Read
```

## Project Structure

```
ACQ_Read/
├── cpp/
│   ├── inc/
│   │   ├── backend/
│   │   │   ├── DSPFilters.h           # DSP filter implementations
│   │   │   ├── ACQDataLoader.h        # ACQ data loading
│   │   │   ├── SignalProcessor.h      # Signal processing utilities
│   │   │   └── DataAnalyzer.h         # Data analysis functions
│   │   ├── controllers/
│   │   │   ├── ApplicationController.h # Main app controller
│   │   │   ├── FilterController.h      # Filter management
│   │   │   └── LabelManager.h          # Label management
│   │   └── models/
│   │       ├── ChannelData.h           # Channel data model
│   │       ├── ACQMetadata.h           # ACQ metadata model
│   │       └── SegmentLabel.h          # Label model
│   └── src/
│       ├── main.cpp                    # Application entry point
│       └── [implementation files]
├── qml/
│   ├── main.qml                        # Main window
│   ├── MainWindow.qml                  # Application layout
│   ├── WaveformView.qml                # Waveform visualization
│   ├── FilterDesignWindow.qml          # Filter design interface
│   ├── LabelingTools.qml               # Labeling tools panel
│   └── LabelOverlay.qml                # Label overlay component
├── python/
│   └── batch_acq_converter.py          # ACQ to JSON/binary converter
└── CMakeLists.txt
```

## Usage

### 1. Loading an ACQ File

1. Click the **"📂 Load ACQ File"** button in the top toolbar
2. Select your `.acq` file from the file dialog
3. The application will:
   - Run the Python converter in the background
   - Convert ACQ data to JSON metadata + binary channel data
   - Load and display the first channel's waveform
4. Status bar will show sample rate, number of samples, and loading status

### 2. Applying Signal Filters

1. Click the **"🎛️ Signal Filter Design"** button (only enabled when data is loaded)
2. A separate filter design window will open showing:
   - Current signal information (Sample Rate, Nyquist Frequency)
   - Filter type selector (Lowpass/Highpass/Bandpass/Notch)
   - Filter parameters specific to the selected type

3. **Lowpass Filter**:
   - Cutoff (Hz): Frequency above which signals are attenuated
   - Order: Filter steepness (1-8)

4. **Highpass Filter**:
   - Cutoff (Hz): Frequency below which signals are attenuated
   - Order: Filter steepness (1-8)

5. **Bandpass Filter**:
   - Low (Hz): Lower cutoff frequency
   - High (Hz): Upper cutoff frequency
   - Order: Filter steepness (1-8)

6. **Notch Filter**:
   - Low (Hz): Lower notch frequency
   - High (Hz): Upper notch frequency
   - Order: Filter steepness (1-8)

7. Click **"Apply Filter"** to process the signal
8. The main waveform will update with the filtered data
9. The filter window will close automatically

**Note**: All cutoff frequencies must be less than the Nyquist frequency (Fs/2). The application validates parameters before applying filters.

### 3. Labeling Signal Segments

1. **Activate Labeling Mode**:
   - Click the **"🏷️ Label"** button in the top toolbar
   - The labeling tools panel will appear on the right side
   - A green indicator "🏷️ Labeling Mode Active" will appear on the waveform
   - Status bar will show "🏷️ Labeling Mode"
   - Click **"🏷️ Hide Labels"** to hide the panel and exit labeling mode

2. **Select a region** on the waveform:
   - Click and drag on the waveform chart to select a time range
   - The selection range will be displayed at the bottom of the waveform
   - Selection shows: start time, end time, and duration in seconds
   - Example: "Selected: 1.234s - 2.567s (Duration: 1.333s)"

3. **Create a label**:
   - Enter a label name in the "Label Name" field (right panel)
   - Select a color from the color picker (9 preset colors available)
   - Click **"Add Label from Selection"** button
   - Button is only enabled when:
     - Label name is entered
     - Valid selection exists
     - Selection start < selection end

4. **View labels**:
   - All labels appear in the "Labels" list in the right panel
   - Each label shows:
     - Label name
     - Time range in seconds (e.g., "1.234s - 2.567s")
     - Color-coded border and indicator
     - Delete button (✕)

5. **Delete labels**:
   - Click the ✕ button next to any label to remove it
   - Click **"Clear All Labels"** to remove all labels at once

6. **Label overlays**:
   - Labels appear as colored semi-transparent rectangles on the waveform
   - Each overlay shows the label name at the top-left corner

7. **Zoom waveform**:
   - Use mouse wheel to zoom in/out on the waveform
   - Scroll up to zoom in (see more detail)
   - Scroll down to zoom out (see broader view)
   - Zoom affects both time (X-axis) and voltage (Y-axis)

### 4. Saving Labels

1. Click the **"💾 Save Labels"** button in the top toolbar
2. Choose a location and filename (JSON format)
3. Labels are saved with:
   - Label ID
   - Start and end indices
   - Label text
   - Color (hex format)

## Technical Details

### DSP Filter Implementation

The application uses Butterworth IIR filters implemented as cascaded second-order sections (biquads) for numerical stability:

- **Filter Design**: Bilinear transform converts analog to digital filters
- **Frequency Normalization**: All frequencies normalized to Nyquist frequency
- **Stability**: Cascaded biquads prevent coefficient quantization errors
- **Real-time**: Filters process signals in a single pass

### ACQ Conversion Process

When loading an ACQ file:

1. Application spawns Python subprocess running `batch_acq_converter.py`
2. Python uses bioread library to parse ACQ file
3. Converter extracts:
   - Channel names and units
   - Sample rate and sample count
   - Raw sample data
4. Output format:
   - `metadata.json`: Channel information and sample rates
   - `channel_0.bin`, `channel_1.bin`, etc.: Float32 binary data per channel
5. C++ backend loads JSON metadata and binary channel data
6. First channel is displayed in waveform view

### Data Format

**JSON Metadata** (`metadata.json`):
```json
{
  "channels": [
    {
      "name": "Channel Name",
      "units": "mV",
      "sample_rate": 1000.0,
      "samples": 10000,
      "binary_file": "channel_0.bin"
    }
  ]
}
```

**Binary Files**: IEEE 754 single-precision floating-point (4 bytes per sample)

### Label JSON Format

The exported JSON file includes comprehensive information about each labeled segment:

```json
{
  "labels": [
    {
      "start_index": 1000,
      "end_index": 2000,
      "start_time": 1.0,
      "end_time": 2.0,
      "label": "Baseline",
      "color": "#FF0000",
      "voltage_data": [0.145, 0.152, 0.148, ...],
      "voltage_min": 0.135,
      "voltage_max": 0.165,
      "voltage_avg": 0.150
    },
    {
      "start_index": 3000,
      "end_index": 4500,
      "start_time": 3.0,
      "end_time": 4.5,
      "label": "Stimulus Response",
      "color": "#00FF00",
      "voltage_data": [0.245, 0.312, 0.298, ...],
      "voltage_min": 0.235,
      "voltage_max": 0.325,
      "voltage_avg": 0.275
    }
  ]
}
```

**Fields Explained**:
- `start_index` / `end_index`: Sample indices marking the segment boundaries
- `start_time` / `end_time`: Time in seconds (calculated from sample rate)
- `label`: Custom name given to the segment
- `color`: Hex color code for visualization
- `voltage_data`: Complete array of voltage values within the segment
- `voltage_min`: Minimum voltage in the segment (mV)
- `voltage_max`: Maximum voltage in the segment (mV)
- `voltage_avg`: Average voltage in the segment (mV)

## Troubleshooting

### "No Signal" Error in Filter Design Window

- Ensure an ACQ file is loaded successfully
- Check status bar for "Fs" and "Samples" indicators
- Reload the ACQ file if conversion failed

### Python Conversion Fails

**Error**: `'NoneType' object is not subscriptable`
- **Cause**: bioread version incompatibility or corrupted ACQ file
- **Solution**: Ensure bioread 3.1.0 is installed:
  ```bash
  pip install bioread==3.1.0
  ```

**Error**: `AttributeError: type object 'JournalHeader' has no attribute 'EXPECTED_TAG_VALUE_HEX'`
- **Cause**: bioread version 2025.5.2 or newer has bugs
- **Solution**: Downgrade to bioread 3.1.0

### Filter Parameters Invalid

- All cutoff frequencies must be positive and less than Nyquist frequency
- For bandpass/notch: Low frequency must be less than High frequency
- Filter order must be between 1 and 8

### Labels Not Appearing

- Ensure a valid selection is made (click and drag on waveform)
- Check that selection indicator shows at bottom of waveform
- Verify label name is entered before clicking "Add Label from Selection"

### Build Errors

**Qt not found**:
- Set Qt6_DIR environment variable to Qt installation path
- Example: `export Qt6_DIR=/usr/local/Qt-6.5.0`

**nlohmann/json not found**:
- Install nlohmann-json library
- Ubuntu: `sudo apt install nlohmann-json3-dev`
- Or download single header from: https://github.com/nlohmann/json

## Developer Notes

### Adding New Filter Types

To add a new filter type:

1. Implement filter in `cpp/src/backend/DSPFilters.cpp`
2. Add Q_INVOKABLE method in `FilterController.h`
3. Update `FilterDesignWindow.qml` with new UI controls
4. Add filter type to ComboBox in `FilterDesignWindow.qml`

### Extending Label Functionality

To add label features:

1. Modify `SegmentLabel` model in `cpp/inc/models/SegmentLabel.h`
2. Update `LabelManager` CRUD operations
3. Extend `LabelingTools.qml` UI
4. Update JSON save/load format in `LabelManager.cpp`

### Working with Multiple Channels

Currently, the application displays the first channel only. To support multiple channels:

1. Add channel selector ComboBox in `MainWindow.qml`
2. Update `ApplicationController::getWaveformData()` to accept channel index
3. Bind channel selector to waveform refresh

## License

This software is provided as-is for DSP engineering and research purposes.

## Contact

For issues, bugs, or feature requests, please contact the development team or submit an issue to the project repository.
