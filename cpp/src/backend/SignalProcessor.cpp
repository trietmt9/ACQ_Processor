#include "SignalProcessor.h"
#include <cmath>
#include <algorithm>
#include <numeric>

SignalProcessor::SignalProcessor() {
}

SignalProcessor::~SignalProcessor() {
}

std::vector<float> SignalProcessor::movingAverage(const std::vector<float>& data, int windowSize) {
    if (data.empty() || windowSize <= 0) {
        return data;
    }

    std::vector<float> result;
    result.reserve(data.size());

    for (size_t i = 0; i < data.size(); ++i) {
        size_t start = (i >= static_cast<size_t>(windowSize / 2)) ? i - windowSize / 2 : 0;
        size_t end = std::min(i + windowSize / 2 + 1, data.size());

        float sum = 0.0f;
        for (size_t j = start; j < end; ++j) {
            sum += data[j];
        }
        result.push_back(sum / (end - start));
    }

    return result;
}

std::vector<float> SignalProcessor::downsample(const std::vector<float>& data, int factor) {
    if (data.empty() || factor <= 0) {
        return data;
    }

    std::vector<float> result;
    result.reserve(data.size() / factor);

    for (size_t i = 0; i < data.size(); i += factor) {
        result.push_back(data[i]);
    }

    return result;
}

float SignalProcessor::calculateRMS(const std::vector<float>& data) {
    if (data.empty()) {
        return 0.0f;
    }

    float sumSquares = 0.0f;
    for (float value : data) {
        sumSquares += value * value;
    }

    return std::sqrt(sumSquares / data.size());
}

std::vector<size_t> SignalProcessor::findPeaks(const std::vector<float>& data, float threshold) {
    std::vector<size_t> peaks;

    if (data.size() < 3) {
        return peaks;
    }

    for (size_t i = 1; i < data.size() - 1; ++i) {
        if (data[i] > threshold &&
            data[i] > data[i - 1] &&
            data[i] > data[i + 1]) {
            peaks.push_back(i);
        }
    }

    return peaks;
}

std::vector<float> SignalProcessor::normalize(const std::vector<float>& data) {
    if (data.empty()) {
        return data;
    }

    auto minmax = std::minmax_element(data.begin(), data.end());
    float min = *minmax.first;
    float max = *minmax.second;
    float range = max - min;

    if (range == 0.0f) {
        return std::vector<float>(data.size(), 0.5f);
    }

    std::vector<float> result;
    result.reserve(data.size());

    for (float value : data) {
        result.push_back((value - min) / range);
    }

    return result;
}

float SignalProcessor::mean(const std::vector<float>& data) {
    if (data.empty()) {
        return 0.0f;
    }
    return std::accumulate(data.begin(), data.end(), 0.0f) / data.size();
}

float SignalProcessor::stdDev(const std::vector<float>& data) {
    if (data.empty()) {
        return 0.0f;
    }

    float m = mean(data);
    float variance = 0.0f;

    for (float value : data) {
        float diff = value - m;
        variance += diff * diff;
    }

    return std::sqrt(variance / data.size());
}
