#include "DataAnalyzer.h"
#include <algorithm>
#include <numeric>
#include <cmath>

DataAnalyzer::DataAnalyzer() {
}

DataAnalyzer::~DataAnalyzer() {
}

DataAnalyzer::Statistics DataAnalyzer::calculateStatistics(const std::vector<float>& data) {
    Statistics stats = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};

    if (data.empty()) {
        return stats;
    }

    // Min and Max
    auto minmax = std::minmax_element(data.begin(), data.end());
    stats.min = *minmax.first;
    stats.max = *minmax.second;

    // Mean
    float sum = std::accumulate(data.begin(), data.end(), 0.0f);
    stats.mean = sum / data.size();

    // Standard deviation
    float variance = 0.0f;
    for (float value : data) {
        float diff = value - stats.mean;
        variance += diff * diff;
    }
    stats.std = std::sqrt(variance / data.size());

    // RMS
    float sumSquares = 0.0f;
    for (float value : data) {
        sumSquares += value * value;
    }
    stats.rms = std::sqrt(sumSquares / data.size());

    // Median
    stats.median = median(data);

    return stats;
}

float DataAnalyzer::median(std::vector<float> data) {
    if (data.empty()) {
        return 0.0f;
    }

    size_t n = data.size();
    std::nth_element(data.begin(), data.begin() + n / 2, data.end());

    if (n % 2 == 0) {
        float m1 = data[n / 2];
        std::nth_element(data.begin(), data.begin() + n / 2 - 1, data.end());
        float m2 = data[n / 2 - 1];
        return (m1 + m2) / 2.0f;
    } else {
        return data[n / 2];
    }
}

std::vector<float> DataAnalyzer::calculatePSD(const std::vector<float>& data, float sampleRate) {
    // Simplified PSD calculation (windowed periodogram)
    // For production, use FFT library like FFTW
    std::vector<float> psd;

    if (data.empty()) {
        return psd;
    }

    // Placeholder: return empty for now
    // TODO: Implement proper FFT-based PSD calculation
    return psd;
}

std::vector<std::pair<size_t, size_t>> DataAnalyzer::detectActivity(
    const std::vector<float>& data, float threshold) {

    std::vector<std::pair<size_t, size_t>> periods;

    if (data.empty()) {
        return periods;
    }

    bool active = false;
    size_t start = 0;

    for (size_t i = 0; i < data.size(); ++i) {
        if (!active && std::abs(data[i]) > threshold) {
            // Activity starts
            active = true;
            start = i;
        } else if (active && std::abs(data[i]) <= threshold) {
            // Activity ends
            active = false;
            periods.push_back({start, i});
        }
    }

    // Handle case where activity continues to end
    if (active) {
        periods.push_back({start, data.size() - 1});
    }

    return periods;
}

float DataAnalyzer::calculateZeroCrossingRate(const std::vector<float>& data) {
    if (data.size() < 2) {
        return 0.0f;
    }

    size_t crossings = 0;
    for (size_t i = 1; i < data.size(); ++i) {
        if ((data[i - 1] >= 0 && data[i] < 0) ||
            (data[i - 1] < 0 && data[i] >= 0)) {
            crossings++;
        }
    }

    return static_cast<float>(crossings) / (data.size() - 1);
}
