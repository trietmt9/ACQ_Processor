#ifndef FILTERCONTROLLER_H
#define FILTERCONTROLLER_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <memory>
#include "DSPFilters.h"
#include "ChannelData.h"

/**
 * @brief Controller for DSP filtering operations (QML-C++ bridge)
 *
 * Provides easy-to-use interface for applying filters from QML
 */
class FilterController : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit FilterController(QObject *parent = nullptr);
    ~FilterController();

    // Property getters
    bool hasData() const { return m_channelData != nullptr; }
    QString lastError() const { return m_lastError; }

    /**
     * @brief Set the channel data to filter
     */
    void setChannelData(std::shared_ptr<ChannelData> channel);

    /**
     * @brief Get current channel data
     */
    std::shared_ptr<ChannelData> getChannelData() const { return m_channelData; }

    // Invokable filter methods (callable from QML)

    /**
     * @brief Apply lowpass filter
     * @param cutoffFreq Cutoff frequency in Hz
     * @param order Filter order (1-8)
     * @return Filtered data as QVariantList of QPointF
     */
    Q_INVOKABLE QVariantList applyLowpass(float cutoffFreq, int order = 4);

    /**
     * @brief Apply highpass filter
     * @param cutoffFreq Cutoff frequency in Hz
     * @param order Filter order (1-8)
     * @return Filtered data as QVariantList of QPointF
     */
    Q_INVOKABLE QVariantList applyHighpass(float cutoffFreq, int order = 4);

    /**
     * @brief Apply bandpass filter
     * @param lowCutoff Low cutoff frequency in Hz
     * @param highCutoff High cutoff frequency in Hz
     * @param order Filter order (1-8)
     * @return Filtered data as QVariantList of QPointF
     */
    Q_INVOKABLE QVariantList applyBandpass(float lowCutoff, float highCutoff, int order = 4);

    /**
     * @brief Apply notch filter
     * @param lowCutoff Low cutoff frequency in Hz
     * @param highCutoff High cutoff frequency in Hz
     * @param order Filter order (1-8)
     * @return Filtered data as QVariantList of QPointF
     */
    Q_INVOKABLE QVariantList applyNotch(float lowCutoff, float highCutoff, int order = 4);

    /**
     * @brief Apply generic filter
     * @param filterType "lowpass", "highpass", "bandpass", or "notch"
     * @param freq1 First frequency parameter
     * @param freq2 Second frequency parameter (for bandpass/notch)
     * @param order Filter order
     * @return Filtered data as QVariantList of QPointF
     */
    Q_INVOKABLE QVariantList applyFilter(const QString& filterType,
                                         float freq1,
                                         float freq2 = 0.0f,
                                         int order = 4);

    /**
     * @brief Get original (unfiltered) data
     * @param maxPoints Maximum number of points to return (for downsampling)
     * @return Original data as QVariantList of QPointF
     */
    Q_INVOKABLE QVariantList getOriginalData(int maxPoints = 10000);

    /**
     * @brief Validate filter parameters
     * @param filterType Filter type string
     * @param freq1 First frequency
     * @param freq2 Second frequency
     * @return True if parameters are valid
     */
    Q_INVOKABLE bool validateFilterParams(const QString& filterType,
                                          float freq1,
                                          float freq2 = 0.0f);

    /**
     * @brief Get sample rate of current channel
     */
    Q_INVOKABLE float getSampleRate() const;

    /**
     * @brief Get Nyquist frequency (sampleRate / 2)
     */
    Q_INVOKABLE float getNyquistFrequency() const;

signals:
    void hasDataChanged();
    void lastErrorChanged();
    void filterApplied(const QString& filterType);
    void filterError(const QString& error);

private:
    std::shared_ptr<ChannelData> m_channelData;
    DSPFilters m_dspFilters;
    QString m_lastError;

    // Helper to convert vector<float> to QVariantList of QPointF
    QVariantList vectorToVariantList(const std::vector<float>& data, int maxPoints = 0);

    // Helper to set error message
    void setError(const QString& error);
};

#endif // FILTERCONTROLLER_H
