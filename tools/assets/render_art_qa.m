#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

static int Fail(NSString *message) {
    fprintf(stderr, "%s\n", message.UTF8String);
    return 1;
}

static NSNumber *Number(id value) {
    return [value isKindOfClass:NSNumber.class] ? value : nil;
}

static NSArray *Pair(id value) {
    if (![value isKindOfClass:NSArray.class] || [(NSArray *)value count] != 2) {
        return nil;
    }
    NSArray *pair = value;
    return Number(pair[0]) && Number(pair[1]) ? pair : nil;
}

static CGColorRef CreateColor(NSString *value) {
    if (![value isKindOfClass:NSString.class]) {
        return nil;
    }
    NSString *hex = [value hasPrefix:@"#"] ? [value substringFromIndex:1] : value;
    if (hex.length != 6) {
        return nil;
    }
    unsigned int rgb = 0;
    if (![[NSScanner scannerWithString:hex] scanHexInt:&rgb]) {
        return nil;
    }
    CGFloat components[] = {
        ((rgb >> 16) & 0xFF) / 255.0,
        ((rgb >> 8) & 0xFF) / 255.0,
        (rgb & 0xFF) / 255.0,
        1.0,
    };
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGColorRef color = CGColorCreate(space, components);
    CGColorSpaceRelease(space);
    return color;
}

static CGImageRef LoadImage(
    NSString *path,
    NSURL *root,
    NSMutableDictionary<NSString *, id> *cache
) {
    id cached = cache[path];
    if (cached != nil) {
        return (__bridge CGImageRef)cached;
    }
    NSURL *url = [root URLByAppendingPathComponent:path];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, nil);
    if (source == nil) {
        return nil;
    }
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, nil);
    CFRelease(source);
    if (image == nil) {
        return nil;
    }
    cache[path] = CFBridgingRelease(image);
    return (__bridge CGImageRef)cache[path];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 4) {
            return Fail(@"usage: render_art_qa <composition.json> <project-root> <output.png>");
        }
        NSURL *sourceURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
        NSURL *rootURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[2]] isDirectory:YES];
        NSURL *outputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[3]]];
        NSData *data = [NSData dataWithContentsOfURL:sourceURL];
        if (data == nil) {
            return Fail(@"cannot read QA composition");
        }
        NSError *jsonError = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (![object isKindOfClass:NSDictionary.class]) {
            return Fail([NSString stringWithFormat:@"invalid QA composition: %@", jsonError]);
        }
        NSDictionary *composition = object;
        NSArray *sourceSize = Pair(composition[@"sourceSizePx"]);
        NSArray *renderSize = Pair(composition[@"renderSizePx"]);
        NSArray *commands = composition[@"renderCommands"];
        if (sourceSize == nil || renderSize == nil || ![commands isKindOfClass:NSArray.class]) {
            return Fail(@"invalid QA composition dimensions/commands");
        }
        size_t width = [renderSize[0] unsignedIntegerValue];
        size_t height = [renderSize[1] unsignedIntegerValue];
        if (width == 0 || height == 0) {
            return Fail(@"invalid QA render dimensions");
        }
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(
            nil,
            width,
            height,
            8,
            width * 4,
            space,
            (CGBitmapInfo)kCGImageAlphaPremultipliedLast
        );
        CGColorSpaceRelease(space);
        if (context == nil) {
            return Fail(@"cannot allocate QA canvas");
        }
        CGFloat scaleX = width / [sourceSize[0] doubleValue];
        CGFloat scaleY = height / [sourceSize[1] doubleValue];
        CGContextTranslateCTM(context, 0, height);
        CGContextScaleCTM(context, scaleX, -scaleY);
        NSMutableDictionary<NSString *, id> *cache = [NSMutableDictionary dictionary];

        for (id rawCommand in commands) {
            if (![rawCommand isKindOfClass:NSDictionary.class]) {
                CGContextRelease(context);
                return Fail(@"invalid QA render command");
            }
            NSDictionary *command = rawCommand;
            NSString *type = command[@"type"];
            if ([type isEqualToString:@"rect"]) {
                NSNumber *x = Number(command[@"x"]);
                NSNumber *y = Number(command[@"y"]);
                NSNumber *w = Number(command[@"width"]);
                NSNumber *h = Number(command[@"height"]);
                NSNumber *radius = Number(command[@"radius"] ?: @0);
                if (!x || !y || !w || !h || !radius) {
                    CGContextRelease(context);
                    return Fail(@"invalid QA rect command");
                }
                CGRect rect = CGRectMake(x.doubleValue, y.doubleValue, w.doubleValue, h.doubleValue);
                CGPathRef path = CGPathCreateWithRoundedRect(
                    rect,
                    radius.doubleValue,
                    radius.doubleValue,
                    nil
                );
                if (command[@"fill"] != nil) {
                    CGColorRef fill = CreateColor(command[@"fill"]);
                    if (fill == nil) {
                        CGPathRelease(path);
                        CGContextRelease(context);
                        return Fail(@"invalid QA rect fill");
                    }
                    CGContextAddPath(context, path);
                    CGContextSetFillColorWithColor(context, fill);
                    CGContextFillPath(context);
                    CGColorRelease(fill);
                }
                if (command[@"stroke"] != nil) {
                    CGColorRef stroke = CreateColor(command[@"stroke"]);
                    NSNumber *strokeWidth = Number(command[@"strokeWidth"] ?: @1);
                    if (stroke == nil || strokeWidth == nil) {
                        if (stroke) CGColorRelease(stroke);
                        CGPathRelease(path);
                        CGContextRelease(context);
                        return Fail(@"invalid QA rect stroke");
                    }
                    CGContextAddPath(context, path);
                    CGContextSetStrokeColorWithColor(context, stroke);
                    CGContextSetLineWidth(context, strokeWidth.doubleValue);
                    CGContextStrokePath(context);
                    CGColorRelease(stroke);
                }
                CGPathRelease(path);
            } else if ([type isEqualToString:@"sprite"]) {
                NSString *path = command[@"runtimePath"];
                NSArray *matrix = command[@"matrix"];
                NSArray *logical = Pair(command[@"logicalSize"]);
                if (![path isKindOfClass:NSString.class] ||
                    ![matrix isKindOfClass:NSArray.class] ||
                    matrix.count != 6 || logical == nil) {
                    CGContextRelease(context);
                    return Fail(@"invalid QA sprite command");
                }
                for (id value in matrix) {
                    if (Number(value) == nil) {
                        CGContextRelease(context);
                        return Fail(@"invalid QA sprite matrix");
                    }
                }
                CGImageRef image = LoadImage(path, rootURL, cache);
                if (image == nil) {
                    CGContextRelease(context);
                    return Fail([NSString stringWithFormat:@"cannot load runtime image: %@", path]);
                }
                CGContextSaveGState(context);
                CGAffineTransform transform = CGAffineTransformMake(
                    [matrix[0] doubleValue],
                    [matrix[1] doubleValue],
                    [matrix[2] doubleValue],
                    [matrix[3] doubleValue],
                    [matrix[4] doubleValue],
                    [matrix[5] doubleValue]
                );
                CGContextConcatCTM(context, transform);
                CGRect rect = CGRectMake(0, 0, [logical[0] doubleValue], [logical[1] doubleValue]);
                CGContextTranslateCTM(context, 0, CGRectGetHeight(rect));
                CGContextScaleCTM(context, 1, -1);
                if (command[@"tint"] != nil) {
                    CGColorRef tint = CreateColor(command[@"tint"]);
                    if (tint == nil) {
                        CGContextRestoreGState(context);
                        CGContextRelease(context);
                        return Fail(@"invalid QA sprite tint");
                    }
                    CGContextClipToMask(context, rect, image);
                    CGContextSetFillColorWithColor(context, tint);
                    CGContextFillRect(context, rect);
                    CGColorRelease(tint);
                } else {
                    CGContextDrawImage(context, rect, image);
                }
                CGContextRestoreGState(context);
            } else {
                CGContextRelease(context);
                return Fail([NSString stringWithFormat:@"unknown QA command: %@", type]);
            }
        }

        CGImageRef result = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        if (result == nil) {
            return Fail(@"cannot create QA result image");
        }
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
            (__bridge CFURLRef)outputURL,
            CFSTR("public.png"),
            1,
            nil
        );
        if (destination == nil) {
            CGImageRelease(result);
            return Fail(@"cannot create QA PNG destination");
        }
        CGImageDestinationAddImage(destination, result, nil);
        BOOL finalized = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        CGImageRelease(result);
        if (!finalized) {
            return Fail(@"cannot finalize QA PNG");
        }
    }
    return 0;
}
