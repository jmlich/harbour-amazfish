
#ifndef DEVICEINTERFACE_H
#define DEVICEINTERFACE_H

#include <QObject>
#include <QtSql/QtSql>
#include <QQueue>
#include <QTimer>

#include <KDb3/KDbDriver>
#include <KDb3/KDbConnection>
#include <KDb3/KDbConnectionData>

#include "abstractdevice.h"
#include "abstractfirmwareinfo.h"
#include "dbushrm.h"
#include "weather/citymanager.h"
#include "weather/currentweather.h"
#include "libwatchfish/musiccontroller.h"
#include "libwatchfish/voicecallcontroller.h"
#include "libwatchfish/notificationmonitor.h"
#include "libwatchfish/notification.h"
#include "libwatchfish/calendarsource.h"

class HRMService;
class MiBand2Service;
class MiBandService;

#define SERVICE_NAME "uk.co.piggz.amazfish"

class DeviceInterface : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", SERVICE_NAME)
public:
    DeviceInterface();
    ~DeviceInterface();

    void registerDBus();

    Q_INVOKABLE QString pair(const QString &name, const QString &address);
    Q_INVOKABLE void connectToDevice(const QString &address);
    Q_INVOKABLE void disconnect();
    Q_INVOKABLE QString connectionState() const;
    Q_INVOKABLE bool operationRunning();
    Q_INVOKABLE bool supportsFeature(int f);
    Q_INVOKABLE int supportedFeatures();

    KDbConnection *dbConnection();

    Q_SIGNAL void message(const QString &text);
    Q_SIGNAL void downloadProgress(int percent);
    Q_SIGNAL void operationRunningChanged();
    Q_SIGNAL void informationChanged(int infoKey, const QString& infoValue);
    Q_SIGNAL void connectionStateChanged();

    //Functions provided by services
    Q_INVOKABLE QString prepareFirmwareDownload(const QString &path);
    Q_INVOKABLE bool startDownload();
    Q_INVOKABLE void downloadSportsData();
    Q_INVOKABLE void downloadActivityData();
    Q_INVOKABLE void refreshInformation();
    Q_INVOKABLE QString information(int i);
    Q_INVOKABLE void sendAlert(const QString &sender, const QString &subject, const QString &message, bool allowDuplicate = false);
    Q_INVOKABLE void incomingCall(const QString &caller);
    Q_INVOKABLE void applyDeviceSetting(int s);
    Q_INVOKABLE void requestManualHeartrate();
    Q_INVOKABLE void triggerSendWeather();
    Q_INVOKABLE void updateCalendar();
    Q_INVOKABLE void reloadCities();
    Q_INVOKABLE void enableFeature(int feature);

private:
    QString m_deviceAddress;
    QString m_deviceName;
    bool m_dbusRegistered = false;
    int m_lastBatteryLevel = 0;
    int m_lastAlertHash = 0;
    AbstractFirmwareInfo *m_firmwareInfo = nullptr;

    AbstractDevice *m_device = nullptr;

    DBusHRM *m_dbusHRM = nullptr;

    QTimer *m_refreshTimer = nullptr;
    Q_SLOT void onRefreshTimer();

    void createSettings();
    void updateServiceController();

    //TODO Minimise use of these funcitons
    MiBandService *miBandService() const;
    HRMService *hrmService() const;
    
    Q_SLOT void onNotification(watchfish::Notification *notification);
    Q_SLOT void onRingingChanged();
    Q_SLOT void onConnectionStateChanged();
    Q_SLOT void slot_informationChanged(AbstractDevice::Info infokey, const QString &infovalue);
    Q_SLOT void musicChanged();
    Q_SLOT void deviceEvent(AbstractDevice::Events event);
    Q_SLOT void buttonPressed(int presses);

    void sendBufferedNotifications();

    //Watchfish
    watchfish::MusicController m_musicController;
    watchfish::VoiceCallController m_voiceCallController;
    watchfish::NotificationMonitor m_notificationMonitor;
    watchfish::CalendarSource m_calendarSource;

    //Notifications
    QQueue<watchfish::Notification*> m_notificationBuffer;

    //Database
    KDbDriver *m_dbDriver = nullptr;
    KDbConnectionData m_connData;
    KDbConnection *m_conn = nullptr;
    void setupDatabase();
    void createTables();

    //Weather
    CityManager m_cityManager;
    CurrentWeather m_currentWeather;
    void sendWeather(CurrentWeather *weather);
    Q_SLOT void onCitiesChanged();
    Q_SLOT void onWeatherReady();
};

#endif // BIPINTERFACE_H
