#ifndef CHARTCONTROLLER_H
#define CHARTCONTROLLER_H

#include <QObject>
#include <QVariantList>
#include <memory>
#include "ChannelData.h"

/**
 * @brief Controller for managing chart data (QML-C++ bridge)
 */
class ChartController : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool hasData READ hasData NOTIFY hasDataChanged)
    Q_PROPERTY(int dataSize READ dataSize NOTIFY dataSizeChanged)

public:
    explicit ChartController(QObject *parent = nullptr);
    ~ChartController();

    // Property getters
    bool hasData() const { return m_hasData; }
    int dataSize() const { return m_dataSize; }

    // Invokable methods
    Q_INVOKABLE QVariantList getChartData(int maxPoints = 10000);
    Q_INVOKABLE QVariantList getDownsampledData(int targetPoints);
    Q_INVOKABLE void setChannelData(int fileIndex, int channelIndex);
    Q_INVOKABLE void clearData();

    // Direct data setting (from C++)
    void setData(std::shared_ptr<ChannelData> channel);

signals:
    void hasDataChanged();
    void dataSizeChanged();

private:
    bool m_hasData;
    int m_dataSize;
    std::shared_ptr<ChannelData> m_channelData;

    QVariantList downsampleData(const std::vector<float>& data, int targetPoints);
};

#endif // CHARTCONTROLLER_H
