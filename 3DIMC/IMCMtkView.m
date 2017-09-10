//
//  IMCMtkView.m
//  3DIMC
//
//  Created by Raul Catena on 9/5/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCMtkView.h"

@interface IMCMtkView()

@property (nonatomic, assign) matrix_float4x4 modelViewProjectionMatrix;

@property (nonatomic, assign) BOOL working;
@property (nonatomic, assign) float ** bufferedData;
@property (nonatomic, assign) int bufferDataLayers;
@property (nonatomic, assign) int bufferDataLayersLoaded;

@end

@implementation IMCMtkView

-(instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if(self)
        _rotationMatrix = [[Matrix4 alloc]init];
    return self;
}

-(void)applyRotationWithCGPoint:(CGPoint)diff{
    
//    float rotX = diff.y * 0.005;
//    float rotY = diff.x * 0.005;
//
//    [self rotateX:rotX Y:0 Z:0];
//    [self rotateX:0 Y:rotY Z:0];
    
    float rotX = diff.y * 0.005;//-1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float rotY = diff.x * 0.005;//-1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    [self rotateX:rotX Y:rotY Z:.0f];
    
}
                                                        
-(void)applyRotationWithInternalState{
    [self applyRotationWithCGPoint:_rotation];
}

-(void)rotateX:(float)angleX Y:(float)angleY Z:(float)angleZ{
//    [self.rotationMatrix rotateAroundX:angleX y:angleY z:angleZ];
    
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(self.rotationMatrix->glkMatrix, &isInvertible),
                                                 GLKVector3Make(1, 0, 0));
    self.rotationMatrix->glkMatrix = GLKMatrix4Rotate(self.rotationMatrix->glkMatrix, angleX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(self.rotationMatrix->glkMatrix, &isInvertible),
                                                 GLKVector3Make(0, 1, 0));
    self.rotationMatrix->glkMatrix = GLKMatrix4Rotate(self.rotationMatrix->glkMatrix, angleY, yAxis.x, yAxis.y, yAxis.z);
}

-(void)mouseDragged:(NSEvent *)theEvent{
    
    if (theEvent.modifierFlags & NSEventModifierFlagCommand) {
        [self.baseModelMatrix translate:theEvent.deltaX * 0.05 y:-theEvent.deltaY * 0.05 z:0];
    }else{
        _rotation.x = theEvent.deltaX;
        _rotation.y = theEvent.deltaY;
        [self applyRotationWithCGPoint:_rotation];
    }
    self.refresh = YES;
}

#define MAX_ALLOWED_ZOOM 1.0f
- (void)scrollWheel:(NSEvent *)theEvent {
    
    //if(![self computeOffSets:theEvent]){
    if(![self scrollWithWheel:theEvent]){
        float value = theEvent.deltaY;
        _zoom += value;
        _zoom = MIN(MAX_ALLOWED_ZOOM, MAX(-MAX_ALLOWED_ZOOM, _zoom));
        if(_zoom > MAX_ALLOWED_ZOOM){
            _zoom = MAX_ALLOWED_ZOOM;
            return;
        }
        if(_zoom < -MAX_ALLOWED_ZOOM){
            _zoom = -MAX_ALLOWED_ZOOM;
            return;
        }
        [self.baseModelMatrix translate:0 y:0 z:value];
    }
    //}
    self.refresh = YES;
}
-(BOOL)scrollWithWheel:(NSEvent *)theEvent{
    float factor = theEvent.deltaX * .01f;
    if (theEvent.modifierFlags & NSEventModifierFlagShift){
        if (theEvent.modifierFlags & NSEventModifierFlagControl)
        [self rotateX:factor Y:.0f Z:.0f];
        else if (theEvent.modifierFlags & NSEventModifierFlagControl)
        [self rotateX:.0f Y:factor Z:.0f];
        else if (theEvent.modifierFlags & NSEventModifierFlagControl)
        [self rotateX:.0f Y:.0f Z:factor];
        else
        [self rotateX:factor Y:factor Z:factor];
        return YES;
    }
    return NO;
}

-(Matrix4 *)baseModelMatrix{
    if(!_baseModelMatrix){
        _baseModelMatrix = [[Matrix4 alloc]init];
        [_baseModelMatrix translate:0 y:0 z:-500];
    }
    return _baseModelMatrix;
}

- (void)mouseUp:(NSEvent *)theEvent {
    
    
}

- (BOOL)acceptsFirstResponder {
    
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self.delegate drawInMTKView:self];
}

-(CGImageRef)captureImageRef{
    
    self.framebufferOnly = NO;
    
    id<MTLTexture> texture = self.currentDrawable.texture;
    NSInteger width = texture.width;
    NSInteger height   = texture.height;
    NSLog(@"W %li H %li", width, height);
    NSInteger rowBytes = width * 4;
    UInt8 * p = malloc(width * height * 4);
    
    [texture getBytes:p bytesPerRow:rowBytes fromRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0];
    for (NSInteger i = 0; i < rowBytes * height; i++)
        if(p[i] > 0)
            printf("%u", p[i]);
    
    CGColorSpaceRef pColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little;
    
    NSInteger selftureSize = width * height * 4;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(nil, p, selftureSize, nil);
    CGImageRef cgImageRef = CGImageCreate(width, height, 8, 32, rowBytes, pColorSpace, bitmapInfo, provider, nil, YES, kCGRenderingIntentDefault);
    
    return cgImageRef;
}



@end
