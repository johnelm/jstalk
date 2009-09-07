/*
 Not only does this plugin load up the JSTalk Listener, so we can talk to Acorn via JSTalk, it also adds support for JavaScript Plugins, via Acorn's plugin API.
 */


#import "JSEnablerPlugIn.h"
#import "ACPlugin.h"
#import <JSTalk/JSTalk.h>
#import <JSTalk/JSCocoaController.h>

@interface JSEnablerPlugIn (SuperSecret)
- (void) findJSCocoaScriptsForPluginManager:(id<ACPluginManager>)pluginManager;
@end


@implementation JSEnablerPlugIn

+ (id) plugin {
    return [[[self alloc] init] autorelease];
}


- (void) didRegister {
    
    // this guy openes up a Distributed Objects port to listen for outside JSTalk commands commands
    [JSTalk listen];
}

- (void) willRegister:(id<ACPluginManager>)pluginManager {
    [self findJSCocoaScriptsForPluginManager:pluginManager];
}

- (void) findJSCocoaScriptsForPluginManager:(id<ACPluginManager>)pluginManager {
    
    NSString *pluginDir = [@"~/Library/Application Support/Acorn/Plug-Ins/" stringByExpandingTildeInPath];
    NSFileManager *fm   = [NSFileManager defaultManager];
    BOOL isDir          = NO;
    
    if (!([fm fileExistsAtPath:pluginDir isDirectory:&isDir] && isDir)) {
        return;
    }
    
    for (NSString *fileName in [fm contentsOfDirectoryAtPath:pluginDir error:nil]) {
        
        if (!([fileName hasSuffix:@".js"] || [fileName hasSuffix:@".jscocoa"] || [fileName hasSuffix:@".jstalk"])) {
            continue;
        }
        
        [pluginManager addFilterMenuTitle:[fileName stringByDeletingPathExtension]
                       withSuperMenuTitle:@"" //@"JSTalk"
                                   target:self
                                   action:@selector(executeScriptForImage:scriptPath:)
                            keyEquivalent:@""
                keyEquivalentModifierMask:0
                               userObject:[pluginDir stringByAppendingPathComponent:fileName]];
    }
}



- (CIImage*) executeScriptForImage:(CIImage*)image scriptPath:(NSString*)scriptPath {
    
    NSError *err            = 0x00;
    NSString *theJavaScript = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:&err];
    
    if (err) {
        NSBeep();
        NSLog(@"%@", err);
        return nil;
    }
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    [jstalk executeString:theJavaScript];
    
    /*
    Our script should look, at least a little bit like this:
    function main(image) {
        // do fancy image stuff
        return image;
    }
    */
    
    JSValueRef returnValue = [[jstalk jsController] callJSFunctionNamed:@"main" withArguments:image, nil];
    
    // Hurray?
    // The main() method should be returning a value at this point, so we're going to 
    // put it back into a cocoa object.  If it's not there, then it'll be nil and that's 
    // ok for our purposes.
    CIImage *acornReturnValue = 0x00;
    
    if (![JSCocoaFFIArgument unboxJSValueRef:returnValue toObject:&acornReturnValue inContext:[[jstalk jsController] ctx]]) {
        return nil;
    }
    
    // fin.
    return acornReturnValue;
}

@end



