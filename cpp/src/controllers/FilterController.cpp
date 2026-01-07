#include "FilterController.h"
#include <QPointF>
#include <iostream>
#include <algorithm>

FilterController::FilterController(QObject *parent)
    : QObject(parent)
{
}

FilterController::~FilterController() {
}

void FilterController::setChannelData(std::shared_ptr<ChannelData> channel) {
    std::cout << "FilterController::setChannelData called" << std::endl;
    m_channelData = channel;
    if (m_channelData) {
        std::cout << "  Channel data set successfully" << std::endl;
        std::cout << "  Sample rate: " << m_channelData->getSampleRate() << " Hz" << std::endl;
        std::cout << "  Num samples: " << m_channelData->getNumSamples() << std::endl;
    } else {
        std::cout << "  WARNING: Channel data is null!" << std::endl;
    }
    emit hasDataChanged();
}

void FilterController::setError(const QString& error) {
    m_lastError = error;
    emit lastErrorChanged();
    emit filterError(error);
}

float FilterController::getSampleRate() const {
    if (!m_channelData) {
        return 0.0f;
    }
    return m_channelData->getSampleRate();
}

float FilterController::getNyquistFrequency() const {
    return getSampleRate() / 2.0f;
}

bool FilterController::validateFilterParams(const QString& filterType,
                                            float freq1,
                                            float freq2) {
    if (!m_channelData) {
        setError("No channel data loaded");
        return false;
    }

    float sampleRate = getSampleRate();
    float nyquist = getNyquistFrequency();

    if (freq1 <= 0 || freq1 >= nyquist) {
        setError(QString("Frequency must be between 0 and %1 Hz (Nyquist)").arg(nyquist));
        return false;
    }

    if (filterType == "bandpass" || filterType == "notch") {
        if (freq2 <= 0 || freq2 >= nyquist) {
            setError(QString("Second frequency must be between 0 and %1 Hz").arg(nyquist));
            return false;
        }
        if (freq2 <= freq1) {
            setError("High cutoff must be greater than low cutoff");
            return false;
        }
    }

    return true;
}

QVariantList FilterController::vectorToVariantList(const std::vector<float>& data, int maxPoints) {
    QVariantList result;

    if (data.empty()) {
        return result;
    }

    size_t numPoints = data.size();

    // Apply downsampling if requested
    if (maxPoints > 0 && static_cast<int>(numPoints) > maxPoints) {
        int step = numPoints / maxPoints;
        for (size_t i = 0; i < numPoints; i += step) {
            result.append(QPointF(i, data[i]));
        }
        // Always include last point
        if (static_cast<int>(numPoints - 1) != result.last().toPointF().x()) {
            result.append(QPointF(numPoints - 1, data.back()));
        }
    } else {
        // Return all points
        for (size_t i = 0; i < numPoints; ++i) {
            result.append(QPointF(i, data[i]));
        }
    }

    return result;
}

QVariantList FilterController::getOriginalData(int maxPoints) {
    if (!m_channelData) {
        setError("No channel data loaded");
        return QVariantList();
    }

    return vectorToVariantList(m_channelData->getData(), maxPoints);
}

QVariantList FilterController::applyLowpass(float cutoffFreq, int order) {
    if (!m_channelData) {
        setError("No channel data loaded");
        return QVariantList();
    }

    if (!validateFilterParams("lowpass", cutoffFreq, 0.0f)) {
        return QVariantList();
    }

    std::cout << "Applying lowpass filter: cutoff=" << cutoffFreq
              << " Hz, order=" << order << std::endl;

    const auto& data = m_channelData->getData();
    float sampleRate = m_channelData->getSampleRate();

    auto filtered = m_dspFilters.lowpass(data, sampleRate, cutoffFreq, order);

    if (!m_dspFilters.getLastError().empty()) {
        setError(QString::fromStdString(m_dspFilters.getLastError()));
        return vectorToVariantList(data);  // Return original on error
    }

    emit filterApplied("lowpass");
    return vectorToVariantList(filtered);
}

QVariantList FilterController::applyHighpass(float cutoffFreq, int order) {
    if (!m_channelData) {
        setError("No channel data loaded");
        return QVariantList();
    }

    if (!validateFilterParams("highpass", cutoffFreq, 0.0f)) {
        return QVariantList();
    }

    std::cout << "Applying highpass filter: cutoff=" << cutoffFreq
              << " Hz, order=" << order << std::endl;

    const auto& data = m_channelData->getData();
    float sampleRate = m_channelData->getSampleRate();

    auto filtered = m_dspFilters.highpass(data, sampleRate, cutoffFreq, order);

    if (!m_dspFilters.getLastError().empty()) {
        setError(QString::fromStdString(m_dspFilters.getLastError()));
        return vectorToVariantList(data);
    }

    emit filterApplied("highpass");
    return vectorToVariantList(filtered);
}

QVariantList FilterController::applyBandpass(float lowCutoff, float highCutoff, int order) {
    if (!m_channelData) {
        setError("No channel data loaded");
        return QVariantList();
    }

    if (!validateFilterParams("bandpass", lowCutoff, highCutoff)) {
        return QVariantList();
    }

    std::cout << "Applying bandpass filter: low=" << lowCutoff
              << " Hz, high=" << highCutoff << " Hz, order=" << order << std::endl;

    const auto& data = m_channelData->getData();
    float sampleRate = m_channelData->getSampleRate();

    auto filtered = m_dspFilters.bandpass(data, sampleRate, lowCutoff, highCutoff, order);

    if (!m_dspFilters.getLastError().empty()) {
        setError(QString::fromStdString(m_dspFilters.getLastError()));
        return vectorToVariantList(data);
    }

    emit filterApplied("bandpass");
    return vectorToVariantList(filtered);
}

QVariantList FilterController::applyNotch(float lowCutoff, float highCutoff, int order) {
    if (!m_channelData) {
        setError("No channel data loaded");
        return QVariantList();
    }

    if (!validateFilterParams("notch", lowCutoff, highCutoff)) {
        return QVariantList();
    }

    std::cout << "Applying notch filter: low=" << lowCutoff
              << " Hz, high=" << highCutoff << " Hz, order=" << order << std::endl;

    const auto& data = m_channelData->getData();
    float sampleRate = m_channelData->getSampleRate();

    auto filtered = m_dspFilters.notch(data, sampleRate, lowCutoff, highCutoff, order);

    if (!m_dspFilters.getLastError().empty()) {
        setError(QString::fromStdString(m_dspFilters.getLastError()));
        return vectorToVariantList(data);
    }

    emit filterApplied("notch");
    return vectorToVariantList(filtered);
}

QVariantList FilterController::applyFilter(const QString& filterType,
                                           float freq1,
                                           float freq2,
                                           int order) {
    QString type = filterType.toLower();

    if (type == "lowpass") {
        return applyLowpass(freq1, order);
    } else if (type == "highpass") {
        return applyHighpass(freq1, order);
    } else if (type == "bandpass") {
        return applyBandpass(freq1, freq2, order);
    } else if (type == "notch") {
        return applyNotch(freq1, freq2, order);
    } else {
        setError("Unknown filter type: " + filterType);
        return QVariantList();
    }
}
