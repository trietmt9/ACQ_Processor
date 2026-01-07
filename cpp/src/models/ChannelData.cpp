#include "ChannelData.h"
#include <fstream>
#include <iostream>
#include <cstring>

ChannelData::ChannelData()
    : index(0)
    , sampleRate(0.0f)
    , numSamples(0)
    , duration(0.0f)
    , min(0.0f)
    , max(0.0f)
    , mean(0.0f)
    , std(0.0f)
{
}

ChannelData::~ChannelData() {
}

void ChannelData::setStatistics(float minVal, float maxVal, float meanVal, float stdVal) {
    min = minVal;
    max = maxVal;
    mean = meanVal;
    std = stdVal;
}

bool ChannelData::loadBinaryData(const std::string& filepath) {
    std::ifstream file(filepath, std::ios::binary | std::ios::ate);

    if (!file.is_open()) {
        std::cerr << "Failed to open binary file: " << filepath << std::endl;
        return false;
    }

    // Get file size
    std::streamsize fileSize = file.tellg();
    file.seekg(0, std::ios::beg);

    // Calculate number of float32 values
    size_t numFloats = fileSize / sizeof(float);

    if (numFloats != numSamples) {
        std::cerr << "Warning: File size mismatch. Expected " << numSamples
                  << " samples but got " << numFloats << std::endl;
    }

    // Read all data
    data.resize(numFloats);
    file.read(reinterpret_cast<char*>(data.data()), fileSize);

    if (!file) {
        std::cerr << "Error reading binary data from: " << filepath << std::endl;
        return false;
    }

    file.close();

    std::cout << "Loaded " << data.size() << " samples from " << filepath << std::endl;
    return true;
}

void ChannelData::setData(const std::vector<float>& newData) {
    data = newData;
    numSamples = data.size();
}
