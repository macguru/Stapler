#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Cocoa/Cocoa.h>

Boolean GetMetadataForFile(void* thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    NSAutoreleasePool *pool;
    NSDictionary *tempDict;
    Boolean success = NO;
    
    pool = [[NSAutoreleasePool alloc] init];
    
    tempDict = [[NSDictionary alloc] initWithContentsOfFile: [(NSString *)pathToFile stringByAppendingPathComponent: @"Info.plist"]];
    
    if (tempDict)
     {
        NSMutableString *text;
        NSArray *keys;
        unsigned i;
        
        keys = [tempDict allKeys];
        text = [[NSMutableString alloc] init];
        
        for (i=0; i<[keys count]; i++) {
            NSAttributedString *part;
            
            part = [[NSAttributedString alloc] initWithPath:[(NSString *)pathToFile stringByAppendingPathComponent: [keys objectAtIndex: i]] documentAttributes:nil];
            [text appendFormat: @"%@ ", [part string]];
            [part release];
        }
        
        [(NSMutableDictionary *)attributes setObject:text forKey:(NSString *)kMDItemTextContent];
        [text release];
        
        success = YES;
        [tempDict release];
     }
    
    [pool release];
    return success;
}
