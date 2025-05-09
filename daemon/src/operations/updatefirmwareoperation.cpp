#include "updatefirmwareoperation.h"
#include "bipfirmwareservice.h"
#include "typeconversion.h"
#include <QApplication>

UpdateFirmwareOperation::UpdateFirmwareOperation(const AbstractFirmwareInfo *info, QBLEService *service, AbstractDevice *device) : m_info(info), m_fwBytes(info->bytes()), m_device(device)
{
}

void UpdateFirmwareOperation::start(QBLEService *service)
{
    m_service = service;
    if (m_info->type() != AbstractFirmwareInfo::Invalid) {
        BipFirmwareService *serv = dynamic_cast<BipFirmwareService*>(m_service);

        m_service->enableNotification(serv->UUID_CHARACTERISTIC_FIRMWARE);

        if (m_startWithFWInfo) {
            sendFwInfo();
        } else {
            //Sending inital 01ff
            QByteArray bytes(2, char(0x00));
            bytes[0] = BipFirmwareService::COMMAND_FIRMWARE_INIT;
            bytes[1] = (char)0xff;

            m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE, bytes);
        }
    } else {
        m_service->message(QObject::tr("File does not seem to be supported"));
    }
}

bool UpdateFirmwareOperation::characteristicChanged(const QString &characteristic, const QByteArray &value)
{
    if (characteristic == BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE) {
        qDebug() << "...got metadata";
        return handleMetaData(value);
    }
    return false;
}

bool UpdateFirmwareOperation::handleMetaData(const QByteArray &value)
{
    qDebug() << Q_FUNC_INFO << value;

    if (!(value.length() == 3 || value.length() == 11)) {
        qDebug() << "Notifications should be 3 or 11 bytes long.";
        return true;
    }
    bool success = value[2] == BipFirmwareService::SUCCESS;

    if (value[0] == BipFirmwareService::RESPONSE && success) {
        switch (value[1]) {
        case BipFirmwareService::COMMAND_FIRMWARE_INIT: {
            if (m_needToSendFwInfo) {
                m_needToSendFwInfo = false;
                if (!sendFwInfo()) {
                    m_service->message("Error sending firmware info, aborting.");
                    //done();
                }
            } else {
                sendFirmwareData();
            }
            break;
        }
        case BipFirmwareService::COMMAND_FIRMWARE_START_DATA: {
            sendChecksum();
            break;
        }
        case BipFirmwareService::COMMAND_FIRMWARE_CHECKSUM: {
            if (m_info->type() == AbstractFirmwareInfo::Firmware) {
                m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE, QByteArray(1, BipFirmwareService::COMMAND_FIRMWARE_REBOOT));
            } else {
                m_service->message(QObject::tr("Update operation complete"));
                return true;
            }
            break;
        }
        case BipFirmwareService::COMMAND_FIRMWARE_REBOOT: {
            qDebug() << "Reboot command successfully sent.";

            return true;
        }
        default: {
            qDebug() << "Unexpected response during firmware update: ";
            //operationFailed();
            m_service->message(QObject::tr("Update operation failed"));
            return true;
        }
        }
        return false;
    }
    
    qDebug() << Q_FUNC_INFO << "Unexpected notification during firmware update: ";
    m_service->message(QObject::tr("Update operation failed, unexpected metadata"));
    return true;

}

void UpdateFirmwareOperation::handleData(const QByteArray &data)
{
    Q_UNUSED(data);
}

bool UpdateFirmwareOperation::sendFwInfo()
{
    int fwSize = m_fwBytes.size();
    QByteArray sizeBytes = TypeConversion::fromInt24(fwSize);
    int arraySize = 4;
    bool isFirmwareCode = m_info->type() == AbstractFirmwareInfo::Firmware;
    if (!isFirmwareCode) {
        arraySize++;
    }
    QByteArray bytes(arraySize, char(0x00));
    int i = 0;
    bytes[i++] = BipFirmwareService::COMMAND_FIRMWARE_INIT;
    bytes[i++] = sizeBytes[0];
    bytes[i++] = sizeBytes[1];
    bytes[i++] = sizeBytes[2];
    if (!isFirmwareCode) {
        bytes[i++] = m_info->type();
    }

    m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE, bytes);
    return true;
}

void UpdateFirmwareOperation::sendFirmwareData() 
{
    int len = m_fwBytes.length();
    int packetLength = 20;
    int packets = len / packetLength;

    // going from 0 to len
    int firmwareProgress = 0;
    int progressPercent = 0;

    BipFirmwareService *serv = dynamic_cast<BipFirmwareService*>(m_service);

    m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE, getFirmwareStartCommand());

    for (int i = 0; i < packets; i++) {
        QByteArray fwChunk = m_fwBytes.mid(i * packetLength, packetLength);

        m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE_DATA, fwChunk);
        firmwareProgress += packetLength;

        progressPercent = (int) ((((float) firmwareProgress) / len) * 100);
        if ((i > 0) && (i % 100 == 0)) {
            m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE, QByteArray(1, BipFirmwareService::COMMAND_FIRMWARE_UPDATE_SYNC));
            m_device->downloadProgress(progressPercent);
            //QApplication::processEvents();

        }
        QThread::msleep(2);
    }

    if (firmwareProgress < len) {
        QByteArray lastChunk = m_fwBytes.mid(packets * packetLength);
        m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE_DATA, lastChunk);
    }

    qDebug() << Q_FUNC_INFO << "Finished sending firmware";
    m_device->downloadProgress(progressPercent);

    m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE, QByteArray(1, BipFirmwareService::COMMAND_FIRMWARE_UPDATE_SYNC));
}


void UpdateFirmwareOperation::sendChecksum() 
{
    int crc16 = m_info->getCrc16();
    m_service->writeValue(BipFirmwareService::UUID_CHARACTERISTIC_FIRMWARE, QByteArray(1, BipFirmwareService::COMMAND_FIRMWARE_CHECKSUM) + TypeConversion::fromInt16(crc16));
}

QByteArray UpdateFirmwareOperation::getFirmwareStartCommand()
{
    return QByteArray(1, BipFirmwareService::COMMAND_FIRMWARE_START_DATA);
}

QString UpdateFirmwareOperation::version()
{
    return m_info->version();
}
