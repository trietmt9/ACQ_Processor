/**
 * @file test_filters.cpp
 * @brief Test program for DSP filters
 *
 * Compile separately with:
 * g++ -std=c++17 -I../inc/backend test_filters.cpp ../src/backend/DSPFilters.cpp -o test_filters -lm
 */

#include <iostream>
#include <vector>
#include <cmath>
#include <fstream>
#include "DSPFilters.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/**
 * @brief Generate a test signal with multiple frequency components
 */
std::vector<float> generateTestSignal(int numSamples, float sampleRate) {
    std::vector<float> signal(numSamples);

    for (int i = 0; i < numSamples; ++i) {
        float t = static_cast<float>(i) / sampleRate;

        // DC offset
        float dc = 2.0f;

        // 10 Hz component (should pass most filters)
        float f10 = 1.0f * std::sin(2.0f * M_PI * 10.0f * t);

        // 50 Hz component (power line noise)
        float f50 = 0.5f * std::sin(2.0f * M_PI * 50.0f * t);

        // 200 Hz component
        float f200 = 0.3f * std::sin(2.0f * M_PI * 200.0f * t);

        // High frequency noise
        float noise = 0.1f * std::sin(2.0f * M_PI * 1000.0f * t);

        signal[i] = dc + f10 + f50 + f200 + noise;
    }

    return signal;
}

/**
 * @brief Calculate RMS of a signal
 */
float calculateRMS(const std::vector<float>& signal) {
    if (signal.empty()) return 0.0f;

    float sumSquares = 0.0f;
    for (float value : signal) {
        sumSquares += value * value;
    }
    return std::sqrt(sumSquares / signal.size());
}

/**
 * @brief Save signal to CSV file for analysis
 */
void saveToCSV(const std::string& filename,
               const std::vector<float>& original,
               const std::vector<float>& filtered) {
    std::ofstream file(filename);

    if (!file.is_open()) {
        std::cerr << "Failed to open " << filename << std::endl;
        return;
    }

    file << "Index,Original,Filtered\n";

    size_t maxSize = std::min(original.size(), filtered.size());
    for (size_t i = 0; i < maxSize; ++i) {
        file << i << "," << original[i] << "," << filtered[i] << "\n";
    }

    file.close();
    std::cout << "Saved to " << filename << std::endl;
}

/**
 * @brief Test lowpass filter
 */
void testLowpass(DSPFilters& filters, const std::vector<float>& signal, float sampleRate) {
    std::cout << "\n=== Testing Lowpass Filter ===" << std::endl;

    float cutoff = 100.0f;  // 100 Hz cutoff
    int order = 4;

    std::cout << "Applying lowpass: cutoff=" << cutoff << " Hz, order=" << order << std::endl;

    auto filtered = filters.lowpass(signal, sampleRate, cutoff, order);

    if (!filters.getLastError().empty()) {
        std::cerr << "Error: " << filters.getLastError() << std::endl;
        return;
    }

    float originalRMS = calculateRMS(signal);
    float filteredRMS = calculateRMS(filtered);

    std::cout << "Original RMS: " << originalRMS << std::endl;
    std::cout << "Filtered RMS: " << filteredRMS << std::endl;
    std::cout << "Reduction: " << ((originalRMS - filteredRMS) / originalRMS * 100.0f) << "%" << std::endl;

    saveToCSV("lowpass_test.csv", signal, filtered);
}

/**
 * @brief Test highpass filter
 */
void testHighpass(DSPFilters& filters, const std::vector<float>& signal, float sampleRate) {
    std::cout << "\n=== Testing Highpass Filter ===" << std::endl;

    float cutoff = 5.0f;  // 5 Hz cutoff to remove DC
    int order = 2;

    std::cout << "Applying highpass: cutoff=" << cutoff << " Hz, order=" << order << std::endl;

    auto filtered = filters.highpass(signal, sampleRate, cutoff, order);

    if (!filters.getLastError().empty()) {
        std::cerr << "Error: " << filters.getLastError() << std::endl;
        return;
    }

    // Check DC removal
    float originalMean = 0.0f;
    float filteredMean = 0.0f;

    for (float v : signal) originalMean += v;
    for (float v : filtered) filteredMean += v;

    originalMean /= signal.size();
    filteredMean /= filtered.size();

    std::cout << "Original mean (DC): " << originalMean << std::endl;
    std::cout << "Filtered mean (DC): " << filteredMean << std::endl;

    saveToCSV("highpass_test.csv", signal, filtered);
}

/**
 * @brief Test bandpass filter
 */
void testBandpass(DSPFilters& filters, const std::vector<float>& signal, float sampleRate) {
    std::cout << "\n=== Testing Bandpass Filter ===" << std::endl;

    float lowCutoff = 10.0f;
    float highCutoff = 150.0f;
    int order = 4;

    std::cout << "Applying bandpass: " << lowCutoff << "-" << highCutoff
              << " Hz, order=" << order << std::endl;

    auto filtered = filters.bandpass(signal, sampleRate, lowCutoff, highCutoff, order);

    if (!filters.getLastError().empty()) {
        std::cerr << "Error: " << filters.getLastError() << std::endl;
        return;
    }

    float originalRMS = calculateRMS(signal);
    float filteredRMS = calculateRMS(filtered);

    std::cout << "Original RMS: " << originalRMS << std::endl;
    std::cout << "Filtered RMS: " << filteredRMS << std::endl;

    saveToCSV("bandpass_test.csv", signal, filtered);
}

/**
 * @brief Test notch filter
 */
void testNotch(DSPFilters& filters, const std::vector<float>& signal, float sampleRate) {
    std::cout << "\n=== Testing Notch Filter ===" << std::endl;

    float lowCutoff = 48.0f;   // Remove 50 Hz +/- 2 Hz
    float highCutoff = 52.0f;
    int order = 4;

    std::cout << "Applying notch: " << lowCutoff << "-" << highCutoff
              << " Hz, order=" << order << std::endl;

    auto filtered = filters.notch(signal, sampleRate, lowCutoff, highCutoff, order);

    if (!filters.getLastError().empty()) {
        std::cerr << "Error: " << filters.getLastError() << std::endl;
        return;
    }

    float originalRMS = calculateRMS(signal);
    float filteredRMS = calculateRMS(filtered);

    std::cout << "Original RMS: " << originalRMS << std::endl;
    std::cout << "Filtered RMS: " << filteredRMS << std::endl;
    std::cout << "50 Hz component should be reduced" << std::endl;

    saveToCSV("notch_test.csv", signal, filtered);
}

int main() {
    std::cout << "========================================" << std::endl;
    std::cout << "  DSP Filters Test Suite" << std::endl;
    std::cout << "========================================" << std::endl;

    // Test parameters
    float sampleRate = 2000.0f;  // 2000 Hz
    int numSamples = 4000;       // 2 seconds of data

    std::cout << "\nGenerating test signal..." << std::endl;
    std::cout << "Sample rate: " << sampleRate << " Hz" << std::endl;
    std::cout << "Samples: " << numSamples << std::endl;
    std::cout << "Duration: " << (numSamples / sampleRate) << " seconds" << std::endl;
    std::cout << "\nSignal components:" << std::endl;
    std::cout << "  - DC offset: 2.0" << std::endl;
    std::cout << "  - 10 Hz sine: amplitude 1.0" << std::endl;
    std::cout << "  - 50 Hz sine: amplitude 0.5" << std::endl;
    std::cout << "  - 200 Hz sine: amplitude 0.3" << std::endl;
    std::cout << "  - 1000 Hz noise: amplitude 0.1" << std::endl;

    auto signal = generateTestSignal(numSamples, sampleRate);

    // Create filter instance
    DSPFilters filters;

    // Run all tests
    testLowpass(filters, signal, sampleRate);
    testHighpass(filters, signal, sampleRate);
    testBandpass(filters, signal, sampleRate);
    testNotch(filters, signal, sampleRate);

    std::cout << "\n========================================" << std::endl;
    std::cout << "  All tests completed!" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << "\nCSV files generated:" << std::endl;
    std::cout << "  - lowpass_test.csv" << std::endl;
    std::cout << "  - highpass_test.csv" << std::endl;
    std::cout << "  - bandpass_test.csv" << std::endl;
    std::cout << "  - notch_test.csv" << std::endl;
    std::cout << "\nVisualize with: python3 -c \"import pandas as pd; import matplotlib.pyplot as plt; ..." << std::endl;

    return 0;
}
