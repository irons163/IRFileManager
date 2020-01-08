//
//  dataDefine.h
//  EnShare
//
//  Created by WeiJun on 2015/2/11.
//  Copyright (c) 2015年 Senao. All rights reserved.
//
#ifndef EnShare_dataDefine_h
#define EnShare_dataDefine_h

#define CONNECT_RETRY_COUNT       3
#define DELETE_LIMIT              45
#define TIMEOUT_INTERVAL          15
#define LONG_TIMEOUT_INTERVAL     40

//Notification Key
#define EnMeshLinkNotification          @"EnMeshLinkNotification"
#define LogoutNotification              @"LogoutNotification"
#define ImportFileAndOpenNotification   @"ImportFileAndOpenNotification"

//UserDefault Key
#define USERNAME_KEY                    @"username"
#define PASSWORD_KEY                    @"password"
#define REMEMBER_KEY                    @"remember"
#define UID_DDNS_KEY                    @"UID_DDNS"
#define DDNS_SELECTED_KEY               @"DDNSSelected"
#define UID_SELECTED_KEY                @"UIDSelected"
#define UID_3G_KEY                      @"%@-3G"
#define UID_WIFI_KEY                    @"%@-WIFI"
#define MODEL_NAME_KEY                  @"ModelName"
#define WLAN_MAC_ADDRESS_KEY            @"WlanMacAddress"
#define FIRWARE_VERSION_KEY             @"version"
#define GET_DEVICE_STATUS_API_KEY       @"GetDeviceStatusAPI"
#define AUTO_UPLOAD_KEY                 @"autoUpload"
#define WIFI_ONLY_KEY                   @"wifiOnly"
#define FIRMWARE_ALERT_KEY              @"firmwareAlert"
#define SYSTEM_LANGUAGES_KEY            @"AppleLanguages"
#define CHANGE_LANGUAGE_KEY             @"changeLanguage"
#define AUTO_UPLOAD_FOLDER_NAME_KEY     @"autoUploadFolderName"
#define AD_KEY                          @"AD"
#define MAC_ADDRESS_KEY                 @"macAddress"
#define PLAYER_RANDOM_BUTTON_STATUS_KEY @"playerRandomBtnStatus"
#define PLAYER_CIRCLE_BUTTON_STATUS_KEY @"playerCircleBtnStatus"
#define REMOTE_SELECTED_KEY             @"RemoteSelected"
#define INTRODUCTION_KEY                @"Introduction"

//port
#define HTTPS_APP_AGENT_PORT   9091
#define HTTP_APP_AGENT_PORT    9090
#define DOWNLOAD_PORT          9000
#define UPLOAD_PORT            2000


//Command
#define LOGIN_COMMAND                       @"Login"
#define GET_STORAGE_INFO_COMMAND            @"GetStorageInfo"
#define GET_FILELIST_UNDER_FOLDER_COMMAND   @"GetFileListUnderFolder"
#define GENERATE_FILE_LIST_BY_TYPE_COMMAND  @"GenerateFileListByType"
#define EDIT_FILENAME_BY_NAME_COMMAND       @"EditFilenameByName"
#define DELETE_FILE_BY_NAME_COMMAND         @"DeleteFileByName"
#define DELETE_FILE_FROM_FILE_LIST_COMMAND  @"DeleteFileFromFileList"
#define GET_FILE_LIST_BY_TYPE_COMMAND       @"GetFileListByType"
#define DELETE_FILE_BY_FILE_NAME_COMMAND    @"DeleteFileByFileName"
#define GET_DEVICE_SETINGS_COMMAND          @"GetDeviceSettings"
#define GET_SYSTEM_INFORMATION_COMMAND      @"GetSystemInformation"
#define CHECK_ALIVE_COMMAND                 @"CheckAlive"
#define RENAME_FILE_IN_FILE_LIST_COMMAND    @"RenameFileInFileList"
#define GET_WLAN_RADIO_SECURITY_COMMAND     @"GetWLanRadioSecurity"
#define GET_SYSTEM_THROUGHPUT_COMMAND       @"GetSystemThroughput"
#define GET_WLAN_RADIOS_COMMAND             @"GetWLanRadios"
#define GET_WLAN_RADIO_SETTINGS_COMMAND     @"GetWLanRadioSettings"
#define SET_WLAN_RADIO_SETTINGS_COMMAND     @"SetWLanRadioSettings"
#define SET_WLAN_RADIO_SECURITY_COMMAND     @"SetWLanRadioSecurity"
#define REBOOT_COMMAND                      @"Reboot"
#define GET_WAN_SETTINGS_COMMAND            @"GetWanSettings"
#define GET_LAN_SETTINGS_COMMAND            @"GetLanSettings"
#define GET_DEVICE_STATUS_COMMAND           @"GetDeviceStatus"
#define DOWNLOAD_DEVICE_CONFIG_FILE_COMMAND @"DownloadDeviceConfigFile"
#define GET_CLIENT_STATUS_COMMAND           @"GetClientStatus"
#define GET_BLOCKED_CLIENT_LIST_COMMAND     @"GetBlockedClientList"
#define EDIT_BLOCKED_CLIENT_LIST_COMMAND    @"EditBlockedClientList"
#define DELETE_BLOCKED_CLIENT_LIST_COMMAND  @"DeleteBlockedClientList"
#define CREATE_FOLDER_COMMAND               @"CreateFolder"
#define UPGRADE_FIRMWARE                    @"DoAutoFirmwareUpdate"
#define ADD_FILE_INRO_PUBLIC_LIST_COMMAND   @"AddFileIntoPublicList"
#define GET_MESH_NODE_SIMPLIFY_INFO_COMMAND @"GetMeshNodeSimplifyInfo"
#define CHECK_GENERATE_PROCESS_BY_TYPE_COMMAND @"CheckGenerateProcessByType"
#define GET_FILELIST_UNDER_FOLDER_IN_FILE_COMMAND   @"GetFileListUnderFolderInFile"

//URL
#define LOGIN_URL                          @"%@://%@:%d/json/Login"

//ack tag
#define LOGIN_ACKTAG                       @"LoginResult"
#define GET_STORAGE_INFO_ACKTAG            @"GetStorageInfoResult"
#define GET_FILELIST_UNDER_FOLDER_ACKTAG   @"GetFileListUnderFolder"
#define GENERATE_FILE_LIST_BY_TYPE_ACKTAG  @"GenerateFileListByTypeResult"
#define EDIT_FILENAME_BY_NAME_ACKTAG       @"EditFilenameByNameResult"
#define DELETE_FILE_BY_NAME_ACKTAG         @"DeleteFileByNameResult"
#define DELETE_FILE_FROM_FILE_LIST_ACKTAG  @"DeleteFileFromFileListResult"
#define GET_FILE_LIST_BY_TYPE_ACKTAG       @"GetFileListByTypeResult"
#define DELETE_FILE_BY_FILE_NAME_ACKTAG    @"DeleteFileByFileNameResult"
#define GET_DEVICE_SETINGS_ACKTAG          @"GetDeviceSettingsResult"
#define GET_SYSTEM_INFORMATION_ACKTAG      @"GetSystemInformationResult"
#define CHECK_ALIVE_ACKTAG                 @"CheckAliveResult"
#define RENAME_FILE_IN_FILE_LIST_ACKTAG    @"RenameFileInFileListResult"
#define GET_WLAN_RADIO_SECURITY_ACKTAG     @"GetWLanRadioSecurityResult"
#define GET_SYSTEM_THROUGHPUT_ACKTAG       @"GetSystemThroughputResult"
#define GET_WLAN_RADIOS_ACKTAG             @"GetWLanRadiosResult"
#define GET_WLAN_RADIO_SETTINGS_ACKTAG     @"GetWLanRadioSettingsResult"
#define SET_WLAN_RADIO_SETTINGS_ACKTAG     @"SetWLanRadioSettingsResult"
#define SET_WLAN_RADIO_SECURITY_ACKTAG     @"SetWLanRadioSecurityResult"
#define REBOOT_ACKTAG                      @"RebootResult"
#define GET_WAN_SETTINGS_ACKTAG            @"GetWanSettingsResult"
#define GET_LAN_SETTINGS_ACKTAG            @"GetLanSettingsResult"
#define GET_DEVICE_STATUS_ACKTAG           @"GetDeviceStatusResult"
#define DOWNLOAD_DEVICE_CONFIG_FILE_ACKTAG @"DownloadDeviceConfigFileResult"
#define GET_CLIENT_STATUS_ACKTAG           @"GetClientStatusResult"
#define GET_BLOCKED_CLIENT_LIST_ACKTAG     @"GetBlockedClientListResult"
#define EDIT_BLOCKED_CLIENT_LIST_ACKTAG    @"EditBlockedClientListResult"
#define DELETE_BLOCKED_CLIENT_LIST_ACKTAG  @"DeleteBlockedClientListResult"
#define CREATE_FOLDER_ACKTAG               @"CreateFolderResult"
#define UPGRADE_ACKTAG                     @"DoAutoFirmwareUpdateResult"
#define ADD_FILE_INRO_PUBLIC_LIST_ACKTAG   @"AddFileIntoPublicListResult"
#define GET_MESH_NODE_SIMPLIFY_INFO_ACKTAG @"GetMeshNodeSimplifyInfoResult"
#define CHECK_GENERATE_PROCESS_BY_TYPE_ACKTAG @"CheckGenerateProcessByTypeResult"
#define GET_FILELIST_UNDER_FOLDER_IN_FILE_ACKTAG   @"GetFileListUnderFolderInFile"

//callback id
#define LOGIN_CALLBACK                       1
#define GET_STORAGE_INFO_CALLBACK            2
#define GET_FILELIST_UNDER_FOLDER_CALLBACK   3
#define GENERATE_FILE_LIST_BY_TYPE_CALLBACK  4
#define EDIT_FILENAME_BY_NAME_CALLBACK       5
#define DELETE_FILE_BY_NAME_CALLBACK         6
#define DELETE_FILE_FROM_FILE_LIST_CALLBACK  7
#define GET_FILE_LIST_BY_TYPE_CALLBACK       8
#define DELETE_FILE_BY_FILE_NAME_CALLBACK    9
#define GET_DEVICE_SETINGS_CALLBACK          10
#define GET_SYSTEM_INFORMATION_CALLBACK      11
#define CHECK_ALIVE_CALLBACK                 12
#define RENAME_FILE_IN_FILE_LIST_CALLBACK    13
#define GET_WLAN_RADIO_SECURITY_CALLBACK     14
#define GET_SYSTEM_THROUGHPUT_CALLBACK       15
#define GET_WLAN_RADIOS_CALLBACK             16
#define GET_WLAN_RADIO_SETTINGS_CALLBACK     17
#define SET_WLAN_RADIO_SETTINGS_CALLBACK     18
#define SET_WLAN_RADIO_SECURITY_CALLBACK     19
#define REBOOT_CALLBACK                      20
#define GET_WAN_SETTINGS_CALLBACK            21
#define GET_LAN_SETTINGS_CALLBACK            22
#define GET_DEVICE_STATUS_CALLBACK           23
#define DOWNLOAD_DEVICE_CONFIG_FILE_CALLBACK 24
#define GET_CLIENT_STATUS_CALLBACK           25
#define GET_BLOCKED_CLIENT_LIST_CALLBACK     26
#define EDIT_BLOCKED_CLIENT_LIST_CALLBACK    27
#define CREATE_FOLDER_CALLBACK               28
#define ADD_FILE_INRO_PUBLIC_LIST_CALLBACK   29
#define DELETE_BLOCKED_CLIENT_LIST_CALLBACK  30
#define GET_MESH_NODE_SIMPLIFY_INFO_CALLBACK 31
#define CHECK_GENERATE_PROCESS_BY_TYPE_CALLBACK 32
#define GET_FILELIST_UNDER_FOLDER_IN_FILE_CALLBACK   33

#endif
