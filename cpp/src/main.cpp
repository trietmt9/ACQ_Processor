#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <iostream>

#include "ApplicationController.h"
#include "FilterController.h"
#include "LabelManager.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // Set application info
    app.setOrganizationName("ACQProcessor");
    app.setOrganizationDomain("acqprocessor.local");
    app.setApplicationName("ACQ Signal Processor");

    // Create controllers
    ApplicationController appController;
    FilterController filterController;
    LabelManager labelManager;

    // Connect application controller to filter controller and label manager
    // When app loads data, pass it to filter controller and label manager
    QObject::connect(&appController, &ApplicationController::waveformUpdated, [&]() {
        std::cout << "\n=== Waveform Updated Signal ===" << std::endl;
        if (appController.getChannelData()) {
            auto channelData = appController.getChannelData();
            std::cout << "Updating controllers..." << std::endl;
            std::cout << "  Sample rate: " << channelData->getSampleRate() << " Hz" << std::endl;
            std::cout << "  Num samples: " << channelData->getNumSamples() << std::endl;

            // IMPORTANT: Always give FilterController the ORIGINAL data, not filtered data
            // This ensures each new filter starts from the original, not accumulating
            auto originalData = appController.getOriginalData();
            if (originalData) {
                std::cout << "  Setting ORIGINAL data in filterController for fresh filtering" << std::endl;
                filterController.setChannelData(originalData);
            } else {
                std::cout << "  No original data, using current data" << std::endl;
                filterController.setChannelData(channelData);
            }

            // Update label manager with current (possibly filtered) voltage data
            labelManager.setSampleRate(channelData->getSampleRate());
            labelManager.setVoltageData(channelData->getData());

            std::cout << "Controllers updated successfully" << std::endl;
        } else {
            std::cerr << "WARNING: No channel data available!" << std::endl;
        }
        std::cout << "===========================\n" << std::endl;
    });

    // Create QML engine
    QQmlApplicationEngine engine;

    // Expose controllers to QML as context properties
    engine.rootContext()->setContextProperty("appController", &appController);
    engine.rootContext()->setContextProperty("filterController", &filterController);
    engine.rootContext()->setContextProperty("labelManager", &labelManager);

    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        std::cerr << "Failed to load QML" << std::endl;
        return -1;
    }

    std::cout << "ACQ Signal Processor started successfully" << std::endl;

    return app.exec();
}
