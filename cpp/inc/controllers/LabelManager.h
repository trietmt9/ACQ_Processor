#ifndef LABELMANAGER_H
#define LABELMANAGER_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <vector>
#include <memory>
#include "SegmentLabel.h"

/**
 * @brief Manages segment labels for waveform annotation
 */
class LabelManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(int labelCount READ labelCount NOTIFY labelCountChanged)
    Q_PROPERTY(QVariantList labels READ getLabelsAsVariant NOTIFY labelsChanged)

public:
    explicit LabelManager(QObject *parent = nullptr);
    ~LabelManager();

    int labelCount() const { return m_labels.size(); }

    /**
     * @brief Add a new segment label
     * @param startIndex Start sample index
     * @param endIndex End sample index
     * @param labelText Label text/name
     * @param color Hex color code (e.g., "#FF0000")
     * @return Label ID
     */
    Q_INVOKABLE int addLabel(int startIndex, int endIndex, const QString& labelText, const QString& color);

    /**
     * @brief Set sample rate for time calculations
     */
    void setSampleRate(float sampleRate) { m_sampleRate = sampleRate; }

    /**
     * @brief Set voltage data for extracting segment voltages
     */
    void setVoltageData(const std::vector<float>& data) { m_voltageData = data; }

    /**
     * @brief Remove label by ID
     */
    Q_INVOKABLE bool removeLabel(int labelId);

    /**
     * @brief Update existing label
     */
    Q_INVOKABLE bool updateLabel(int labelId, int startIndex, int endIndex, const QString& labelText, const QString& color);

    /**
     * @brief Clear all labels
     */
    Q_INVOKABLE void clearLabels();

    /**
     * @brief Get label at specific index
     */
    Q_INVOKABLE QVariantMap getLabelAt(int sampleIndex);

    /**
     * @brief Get all labels as QVariantList for QML
     */
    Q_INVOKABLE QVariantList getLabelsAsVariant() const;

    /**
     * @brief Save labels to JSON file
     */
    Q_INVOKABLE bool saveToFile(const QString& filePath);

    /**
     * @brief Load labels from JSON file
     */
    Q_INVOKABLE bool loadFromFile(const QString& filePath);

    // C++ access
    const std::vector<std::shared_ptr<SegmentLabel>>& getLabels() const { return m_labels; }

signals:
    void labelCountChanged();
    void labelsChanged();
    void labelAdded(int labelId);
    void labelRemoved(int labelId);
    void labelUpdated(int labelId);

private:
    std::vector<std::shared_ptr<SegmentLabel>> m_labels;
    float m_sampleRate;
    std::vector<float> m_voltageData;

    std::shared_ptr<SegmentLabel> findLabelById(int id);
};

#endif // LABELMANAGER_H
