//
//  AuthInstallerPane.m
//  auth
//
//  Created by Factorfx Factorfx on 08/08/2022.
//


#import "AuthInstallerPane.h"

@implementation AuthInstallerPane

- (NSString *)title
{
    return [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"PaneTitle" value:nil table:nil];
}


- (void)didEnterPane:(InstallerSectionDirection)dir {
    
    filemgr = [ NSFileManager defaultManager];
    tmpCfgFilePath = @"/tmp/ocs_installer/ocsinventory-agent.cfg";
    
    // if there is no cfg file in the tmp dir, user does not want to overwrite current config = skip auth
    if (![filemgr fileExistsAtPath:@"/tmp/ocs_installer/ocsinventory-agent.cfg"]) {
        [self gotoNextPane];
    }
    
}


- (BOOL)shouldExitPane:(InstallerSectionDirection)Direction {
    NSString *authConfig = @"";

    // check the direction of movement
    if (Direction == InstallerDirectionForward) {
        NSOutputStream *stream = [[NSOutputStream alloc] initToFileAtPath:tmpCfgFilePath append:YES];
        [stream open];
        
        if ( [[authUser stringValue] length] > 0) {
            authConfig = [authConfig stringByAppendingString:@"user="];
            NSData *user = [[authUser stringValue] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *userEncoded = [user base64EncodedStringWithOptions:kNilOptions];
            authConfig = [authConfig stringByAppendingString:userEncoded];
            authConfig =  [authConfig stringByAppendingString:@"\n"];
        }
        
        if ( [[authPwd stringValue] length] > 0) {
            authConfig = [authConfig stringByAppendingString:@"password="];
            NSData *pwd = [[authPwd stringValue] dataUsingEncoding:NSUTF8StringEncoding];
            NSString *pwdEncoded = [pwd base64EncodedStringWithOptions:kNilOptions];
            authConfig = [authConfig stringByAppendingString:pwdEncoded];
            authConfig = [authConfig stringByAppendingString:@"\n"];
        }
        
        if ( [[authRealm stringValue] length] > 0) {
            authConfig = [authConfig stringByAppendingString:@"realm="];
            authConfig = [authConfig stringByAppendingString:[authRealm objectValue]];
            authConfig = [authConfig stringByAppendingString:@"\n"];
        }
        NSData *strData = [authConfig dataUsingEncoding:NSUTF8StringEncoding];
        [stream write:(uint8_t *)[strData bytes] maxLength:[strData length]];


        [stream close];
        
    }
    return (YES);
}

@end
