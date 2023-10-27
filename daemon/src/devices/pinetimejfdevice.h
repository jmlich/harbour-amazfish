#ifndef PINETIMEJFDEVICE_H
#define PINETIMEJFDEVICE_H

#include <QObject>
#include "abstractdevice.h"

class PinetimeJFDevice : public AbstractDevice
{
public:
    explicit PinetimeJFDevice(const QString &pairedName, QObject *parent = 0);

    virtual void pair() override;
    virtual int supportedFeatures() const override;
    virtual QString deviceType() const override;
    virtual void abortOperations() override;

    virtual void sendAlert(const QString &sender, const QString &subject, const QString &message) override;
    virtual void incomingCall(const QString &caller) override;

    virtual void refreshInformation() override;
    virtual QString information(Info i) const override;

    Q_SLOT void authenticated(bool ready);

    virtual void setMusicStatus(bool playing, const QString &title, const QString &artist, const QString &album, int duration = 0, int position = 0) override;

    void prepareFirmwareDownload(const AbstractFirmwareInfo *info) override;
    virtual void startDownload() override;
    virtual AbstractFirmwareInfo *firmwareInfo(const QByteArray &bytes) override;

    //Navigation
    virtual void navigationRunning(bool running) override;
    virtual void navigationNarrative(const QString &flag, const QString &narrative, const QString &manDist, int progress) override;

    //Weather
    virtual void sendWeather(CurrentWeather *weather) override;

    virtual QStringList getFileList(const QString &path) override;

protected:
    virtual void onPropertiesChanged(QString interface, QVariantMap map, QStringList list);

private:
    void parseServices();
    void initialise();
    Q_SLOT void serviceEvent(const QString &characteristic, uint8_t event);
    AbstractFirmwareInfo::Type firmwareType;

};

#endif // PINETIMEJFDEVICE_H
