#define MJShowDockIconKey            @"MJShowDockIconKey"
#define MJShowMenuIconKey            @"MJShowMenuIconKey"
#define MJKeepConsoleOnTopKey        @"MJKeepConsoleOnTopKey"
#define MJHasRunAlreadyKey           @"MJHasRunAlreadyKey"
#define HSAutoLoadExtensions         @"HSAutoLoadExtensions"
#define HSUploadCrashDataKey         @"HSUploadCrashData"
#define HSAppleScriptEnabledKey      @"HSAppleScriptEnabledKey"
#define HSOpenConsoleOnDockClickKey  @"HSOpenConsoleOnDockClickKey"
#define HSConsoleDarkModeKey         @"HSConsoleDarkModeKey"
#define HSPreferencesDarkModeKey     @"HSPreferencesDarkModeKey"

extern NSString* MJConfigFile;

BOOL HSUploadCrashData(void);
void HSSetUploadCrashData(BOOL uploadCrashData);
BOOL PreferencesDarkModeEnabled(void);
void PreferencesDarkModeSetEnabled(BOOL enabled);
