#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 5) {
            fprintf(stderr, "usage: render_svg_appkit <input.svg> <output.png> <width> <height>\n");
            return 2;
        }
        NSString *input = [NSString stringWithUTF8String:argv[1]];
        NSString *output = [NSString stringWithUTF8String:argv[2]];
        NSInteger width = [[NSString stringWithUTF8String:argv[3]] integerValue];
        NSInteger height = [[NSString stringWithUTF8String:argv[4]] integerValue];
        if (width <= 0 || height <= 0) {
            fprintf(stderr, "invalid output dimensions\n");
            return 2;
        }

        NSImage *image = [[NSImage alloc] initWithContentsOfFile:input];
        if (image == nil) {
            fprintf(stderr, "AppKit could not decode SVG: %s\n", argv[1]);
            return 1;
        }
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes:NULL
            pixelsWide:width
            pixelsHigh:height
            bitsPerSample:8
            samplesPerPixel:4
            hasAlpha:YES
            isPlanar:NO
            colorSpaceName:NSDeviceRGBColorSpace
            bitmapFormat:0
            bytesPerRow:0
            bitsPerPixel:0];
        if (bitmap == nil) {
            fprintf(stderr, "AppKit could not allocate bitmap\n");
            return 1;
        }
        bitmap.size = NSMakeSize(width, height);

        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
        if (context == nil) {
            [NSGraphicsContext restoreGraphicsState];
            fprintf(stderr, "AppKit could not create graphics context\n");
            return 1;
        }
        NSGraphicsContext.currentContext = context;
        context.imageInterpolation = NSImageInterpolationHigh;
        CGContextClearRect(context.CGContext, CGRectMake(0, 0, width, height));
        [image drawInRect:NSMakeRect(0, 0, width, height)
                 fromRect:NSZeroRect
                operation:NSCompositingOperationCopy
                 fraction:1.0
           respectFlipped:NO
                    hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
        [context flushGraphics];
        [NSGraphicsContext restoreGraphicsState];

        NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        if (png == nil || ![png writeToFile:output atomically:YES]) {
            fprintf(stderr, "AppKit could not encode/write PNG\n");
            return 1;
        }
    }
    return 0;
}
