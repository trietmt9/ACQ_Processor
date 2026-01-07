#include "DSPFilters.h"
#include <cmath>
#include <algorithm>
#include <iostream>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

DSPFilters::DSPFilters() {
}

DSPFilters::~DSPFilters() {
}

bool DSPFilters::validateParameters(float sampleRate, float freq1, float freq2) {
    if (sampleRate <= 0) {
        lastError = "Sample rate must be positive";
        return false;
    }

    float nyquist = sampleRate / 2.0f;

    if (freq1 <= 0 || freq1 >= nyquist) {
        lastError = "Frequency must be between 0 and Nyquist frequency (" +
                    std::to_string(nyquist) + " Hz)";
        return false;
    }

    if (freq2 > 0 && (freq2 <= 0 || freq2 >= nyquist)) {
        lastError = "Second frequency must be between 0 and Nyquist frequency";
        return false;
    }

    if (freq2 > 0 && freq2 <= freq1) {
        lastError = "High cutoff must be greater than low cutoff";
        return false;
    }

    return true;
}

std::vector<float> DSPFilters::lowpass(const std::vector<float>& data,
                                       float sampleRate,
                                       float cutoffFreq,
                                       int order) {
    return applyFilter(data, sampleRate, LOWPASS, cutoffFreq, 0.0f, order);
}

std::vector<float> DSPFilters::highpass(const std::vector<float>& data,
                                        float sampleRate,
                                        float cutoffFreq,
                                        int order) {
    return applyFilter(data, sampleRate, HIGHPASS, cutoffFreq, 0.0f, order);
}

std::vector<float> DSPFilters::bandpass(const std::vector<float>& data,
                                        float sampleRate,
                                        float lowCutoff,
                                        float highCutoff,
                                        int order) {
    return applyFilter(data, sampleRate, BANDPASS, lowCutoff, highCutoff, order);
}

std::vector<float> DSPFilters::notch(const std::vector<float>& data,
                                     float sampleRate,
                                     float lowCutoff,
                                     float highCutoff,
                                     int order) {
    return applyFilter(data, sampleRate, NOTCH, lowCutoff, highCutoff, order);
}

std::vector<float> DSPFilters::applyFilter(const std::vector<float>& data,
                                           float sampleRate,
                                           FilterType type,
                                           float freq1,
                                           float freq2,
                                           int order) {
    if (data.empty()) {
        lastError = "Input data is empty";
        return data;
    }

    if (order <= 0 || order > 8) {
        lastError = "Filter order must be between 1 and 8";
        return data;
    }

    // Validate parameters
    if (!validateParameters(sampleRate, freq1, freq2)) {
        std::cerr << "Filter validation error: " << lastError << std::endl;
        return data;
    }

    // For bandpass and notch, use cascaded filters
    if (type == BANDPASS) {
        // Bandpass = Highpass(lowCutoff) -> Lowpass(highCutoff)
        auto temp = highpass(data, sampleRate, freq1, order);
        return lowpass(temp, sampleRate, freq2, order);
    } else if (type == NOTCH) {
        // Notch = Input - Bandpass
        auto bandpassed = bandpass(data, sampleRate, freq1, freq2, order);
        std::vector<float> result(data.size());
        for (size_t i = 0; i < data.size(); ++i) {
            result[i] = data[i] - bandpassed[i];
        }
        return result;
    }

    // Design biquad sections
    auto sections = designBiquadSections(type, sampleRate, freq1, freq2, order);

    // Apply cascaded biquads
    return applyCascadedBiquads(data, sections);
}

float DSPFilters::prewarpFrequency(float freq, float sampleRate) {
    return std::tan(M_PI * freq / sampleRate);
}

DSPFilters::ButterworthCoeffs DSPFilters::designLowpass(float sampleRate,
                                                         float cutoffFreq,
                                                         int order) {
    ButterworthCoeffs coeffs;

    // Prewarp cutoff frequency
    float omega = prewarpFrequency(cutoffFreq, sampleRate);

    // For simplicity, implement 2nd order lowpass (biquad)
    // Can be cascaded for higher orders
    float omega2 = omega * omega;
    float sqrt2omega = std::sqrt(2.0f) * omega;

    float a0 = 1.0f + sqrt2omega + omega2;
    float a1 = 2.0f * (omega2 - 1.0f);
    float a2 = 1.0f - sqrt2omega + omega2;

    float b0 = omega2;
    float b1 = 2.0f * omega2;
    float b2 = omega2;

    // Normalize by a0
    coeffs.b = {b0 / a0, b1 / a0, b2 / a0};
    coeffs.a = {1.0f, a1 / a0, a2 / a0};

    return coeffs;
}

DSPFilters::ButterworthCoeffs DSPFilters::designHighpass(float sampleRate,
                                                          float cutoffFreq,
                                                          int order) {
    ButterworthCoeffs coeffs;

    // Prewarp cutoff frequency
    float omega = prewarpFrequency(cutoffFreq, sampleRate);

    // For simplicity, implement 2nd order highpass (biquad)
    float omega2 = omega * omega;
    float sqrt2omega = std::sqrt(2.0f) * omega;

    float a0 = 1.0f + sqrt2omega + omega2;
    float a1 = 2.0f * (omega2 - 1.0f);
    float a2 = 1.0f - sqrt2omega + omega2;

    float b0 = 1.0f;
    float b1 = -2.0f;
    float b2 = 1.0f;

    // Normalize by a0
    coeffs.b = {b0 / a0, b1 / a0, b2 / a0};
    coeffs.a = {1.0f, a1 / a0, a2 / a0};

    return coeffs;
}

std::vector<DSPFilters::ButterworthCoeffs> DSPFilters::designBiquadSections(
    FilterType type,
    float sampleRate,
    float freq1,
    float freq2,
    int order) {

    std::vector<ButterworthCoeffs> sections;

    // Number of second-order sections needed
    int numSections = (order + 1) / 2;

    // Design each biquad section
    for (int i = 0; i < numSections; ++i) {
        ButterworthCoeffs coeffs;

        if (type == LOWPASS) {
            coeffs = designLowpass(sampleRate, freq1, 2);
        } else if (type == HIGHPASS) {
            coeffs = designHighpass(sampleRate, freq1, 2);
        }

        sections.push_back(coeffs);
    }

    return sections;
}

std::vector<float> DSPFilters::applyIIR(const std::vector<float>& data,
                                        const ButterworthCoeffs& coeffs) {
    if (data.empty()) {
        return data;
    }

    std::vector<float> output(data.size(), 0.0f);

    // Direct Form II Transposed implementation
    std::vector<float> state(coeffs.a.size() - 1, 0.0f);

    for (size_t n = 0; n < data.size(); ++n) {
        // Compute output
        float y = coeffs.b[0] * data[n];

        if (state.size() > 0) {
            y += state[0];
        }

        output[n] = y;

        // Update state variables
        for (size_t i = 0; i < state.size() - 1; ++i) {
            state[i] = state[i + 1] + coeffs.b[i + 1] * data[n] - coeffs.a[i + 1] * y;
        }

        if (state.size() > 0) {
            size_t last = state.size() - 1;
            state[last] = coeffs.b[last + 1] * data[n] - coeffs.a[last + 1] * y;
        }
    }

    return output;
}

std::vector<float> DSPFilters::applyCascadedBiquads(
    const std::vector<float>& data,
    const std::vector<ButterworthCoeffs>& sections) {

    if (sections.empty()) {
        return data;
    }

    // Apply each section sequentially
    std::vector<float> result = data;

    for (const auto& section : sections) {
        result = applyIIR(result, section);
    }

    return result;
}
