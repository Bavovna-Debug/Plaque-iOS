//
//  Plaque'n'Play
//
//  Copyright (c) 2015 Meine Werke. All rights reserved.
//

#ifndef __API__
#define __API__

#define API_DialogueSignature						0xC2D6D5D1D6E4D900

#define API_PaquetSignature                     	0xC8C1D360F9F0F0F0

#define API_TokenBinarySize							16
#define API_NotificationsTokenBinarySize			32
#define API_NotificationsTokenStringSize			64

#define API_DeviceBooleanFalse						0x00
#define API_DeviceBooleanTrue						0x01

#define API_DialogueTypeAnticipant					0xD1A0000A
#define API_DialogueTypeRegular						0xD1A0000B

#define API_DeviceTypeAppleiPhone					0xAE1E
#define API_DeviceTypeAppleiPad						0xAE1D

#define API_DialogueVerdictWelcome					0xBED10000
#define API_DialogueVerdictInvalidDevice			0xBED10001
#define API_DialogueVerdictInvalidProfile			0xBED10002
#define API_DialogueVerdictNewSession				0xBED10004

#define API_PaquetBroadcast 		               	0x00010000
#define API_PaquetDisplacementOnRadar               0x00010101
#define API_PaquetDisplacementInSight               0x00010102
#define API_PaquetDisplacementOnMap                 0x00010104
#define API_PaquetDownloadPlaquesOnRadar            0x00010201
#define API_PaquetDownloadPlaquesInSight            0x00010202
#define API_PaquetDownloadPlaquesOnMap              0x00010204
#define API_PaquetPostNewPlaque                     0x00020001
#define API_PaquetPlaqueModifiedLocation            0x00020002
#define API_PaquetPlaqueModifiedOrientation         0x00020003
#define API_PaquetPlaqueModifiedSize                0x00020004
#define API_PaquetPlaqueModifiedColors              0x00020005
#define API_PaquetPlaqueModifiedFont	            0x00020006
#define API_PaquetPlaqueModifiedInscription         0x00020007
#define API_PaquetDownloadProfiles                  0x00030001
#define API_PaquetNotificationsToken                0x00040000
#define API_PaquetValidateProfileName               0x00040001
#define API_PaquetCreateProfile                     0x00040002

#define API_PaquetReportMessage                     0xA1A1A1A1

#define API_PaquetRejectBusy						0xFBFB0000
#define API_PaquetRejectError			 			0xFEFE0000

#define API_PaquetPlaqueStrobe						0xA0B0C0D0

#define API_AnticipantDeviceNameLength              40
#define API_AnticipantDeviceModelLength             20
#define API_AnticipantSystemNamelLength             20
#define API_AnticipantSystemVersionlLength          20

#define API_MinimumProfileNameLength                4
#define API_BonjourProfileNameLength                20
#define API_BonjourUserNameLength                   50
#define API_BonjourMD5Length                        32
#define API_BonjourEmailAddressLength               200

#define API_PaquetNotificationsTokenAccepted        0xA0A00000
#define API_PaquetNotificationsTokenDeclined        0xA0A0FEFE

#define API_PaquetProfileNameAvailable              0xA0A10000
#define API_PaquetProfileNameAlreadyInUse           0xA0A1FEFE

#define API_PaquetDisplacementSucceeded             0xA0A20000
#define API_PaquetDisplacementFailed	            0xA0A2FEFE

#define API_PaquetCreatePlaqueSucceeded             0xA0A40000
#define API_PaquetCreatePlaqueError                 0xA0A4FEFE

#define API_BroadcastDestinationOnRadar				0xBDBD0001
#define API_BroadcastDestinationInSight				0xBDBD0002
#define API_BroadcastDestinationOnMap				0xBDBD0004

#define API_BonjourCreateSucceeded					0xA1A00000
#define API_BonjourCreateProfileNameAlreadyInUse	0xA1A0FE03
#define API_BonjourCreateProfileNameConstraint		0xA1A0FE04
#define API_BonjourCreateProfileEmailAlreadyInUse	0xA1A0FE05
#define API_BonjourCreateProfileEmailConstraint		0xA1A0FE06

#endif
