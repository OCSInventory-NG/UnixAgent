//
//  AutInstallerPane.h
//  auth
//
//  Created by Factorfx Factorfx on 08/08/2022.
//

#import <InstallerPlugins/InstallerPlugins.h>

@interface AuthInstallerPane : InstallerPane {
    IBOutlet NSTextField *authUser;
    IBOutlet NSTextField *authPwd;
    IBOutlet NSTextField *authRealm;

    NSFileManager *filemgr;
    NSString *tmpCfgFilePath;
}

@end
