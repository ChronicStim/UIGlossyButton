//
//  UIButton+Effects.m
//  fwMeCard
//
//  Created by Water Lou on 6/1/11.
//  Copyright 2011 First Water Tech Ltd. All rights reserved.
//


#import "UIGlossyButton.h"
#import "CPTSoundEngine.h"

static void RetinaAwareUIGraphicsBeginImageContext(CGSize size) {
    if ([[UIView class] instancesRespondToSelector:@selector(contentScaleFactor)]) {
		UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
	}
	else {
		UIGraphicsBeginImageContext(size);
	}
}



@implementation UIButton(UIGlossyButton)

- (void) useWhiteLabel : (BOOL) dimOnClickedOrDisabled {
	[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	UIColor *dimColor = nil;
	if (dimOnClickedOrDisabled) dimColor = [UIColor lightGrayColor];
	[self setTitleColor:dimColor forState:UIControlStateDisabled];
	[self setTitleColor:dimColor forState:UIControlStateHighlighted];
}

- (void) useBlackLabel : (BOOL) dimOnClickedOrDisabled {
	[self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	UIColor *dimColor = nil;
	if (dimOnClickedOrDisabled) dimColor = [UIColor darkGrayColor];
	[self setTitleColor:dimColor forState:UIControlStateDisabled];
	[self setTitleColor:dimColor forState:UIControlStateHighlighted];
}

@end


@implementation UIColor(UIGlossyButton)

+ (UIColor*) doneButtonColor {
	return [UIColor colorWithRed:34.0f/255.0f green:96.0f/255.0f blue:221.0f/255.0f alpha:1.0f];	// DONE
}

+ (UIColor*) navigationBarButtonColor {
	return [UIColor colorWithRed:72.0f/255.0f green:106.0f/255.0f blue:154.0f/255.0f alpha:1.0f];	
}

@end


#pragma =================================================
#pragma =================================================
#pragma =================================================


@interface UIGlossyButton()

// main draw routine, not including stroke the outer path
- (void) drawTintColorButton : (CGContextRef)context tintColor : (UIColor *) tintColor isSelected : (BOOL) isSelected;
- (void) strokeButton : (CGContextRef)context color : (UIColor *)color isSelected : (BOOL) isSelected;

@end

@implementation UIGlossyButton

@synthesize tintColor = _tintColor, disabledColor = _disabledColor;
@synthesize buttonCornerRadius = _buttonCornerRadius;
@synthesize borderColor = _borderColor, disabledBorderColor = _disabledBorderColor;
@synthesize buttonBorderWidth = _buttonBorderWidth;
@synthesize innerBorderWidth = _innerBorderWidth;
@synthesize strokeType = _strokeType, extraShadingType = _extraShadingType;
@synthesize backgroundOpacity = _backgroundOpacity;
@synthesize buttonInsets = _buttonInsets;
@synthesize invertGraidentOnSelected = _invertGraidentOnSelected;
@synthesize playSoundWhenPressed = _playSoundWhenPressed;

#pragma lifecycle


- (void) setupSelf {
    _buttonCornerRadius = 4.0f;
	_innerBorderWidth = 1.0;
	_buttonBorderWidth = 1.0;
	_backgroundOpacity = 1.0;
    _buttonInsets = UIEdgeInsetsZero;
    _playSoundWhenPressed = NO;
	[self setGradientType: kUIGlossyButtonGradientTypeLinearSmoothStandard];
    [self addObserver:self forKeyPath:@"highlighted" options:0 context:nil];
    [self addObserver:self forKeyPath:@"enabled" options:0 context:nil];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setupSelf];
    }
    return self;    
}

- (id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setupSelf];        
    }
    return self;
}

-(void) dealloc {
    [self removeObserver:self forKeyPath:@"highlighted"];
    [self removeObserver:self forKeyPath:@"enabled"];
    
#if !__has_feature(objc_arc)
    self.tintColor = nil;
    self.disabledColor = nil;
    self.borderColor = nil;
	self.disabledColor = nil;
    [super dealloc];
#endif
}

#pragma mark - Sound Effects

-(BOOL)playSoundWhenPressed;
{
    return _playSoundWhenPressed;
}

-(void)setPlaySoundWhenPressed:(BOOL)playSound;
{
    if (playSound != _playSoundWhenPressed) {
        _playSoundWhenPressed = playSound;
    }
    
    if (_playSoundWhenPressed) {
        [self addTarget:self action:@selector(playTapSound:) forControlEvents:UIControlEventTouchDown];
    } else {
        [self removeTarget:self action:@selector(playTapSound:) forControlEvents:UIControlEventTouchDown];
    }
}

-(void)playTapSound:(id)sender;
{
    [[CPTSoundEngine sharedCPTSoundEngine] playSoundForObject:self];
}

#pragma mark - 

/* graident that will be used to fill on top of the button for 3D effect */
- (void) setGradientType : (UIGlossyButtonGradientType) type {
	switch (type) {
		case kUIGlossyButtonGradientTypeLinearSmoothStandard:
		{
			static const CGFloat g0[] = {0.5, 1.0, 0.35, 1.0};
			background_gradient = g0;
			locations = nil;
			numberOfColorsInGradient = 2;
		}
			break;
		case kUIGlossyButtonGradientTypeLinearSmoothExtreme:
		{
			static const CGFloat g0[] = {0.8, 1.0, 0.2, 1.0};
			background_gradient = g0;
			locations = nil;
			numberOfColorsInGradient = 2;
		}
			break;
		case kUIGlossyButtonGradientTypeLinearSmoothBrightToNormal:
		{
			static const CGFloat g0[] = {0.9, 1.0, 0.5, 1.0, 0.5, 1.0};
			static const CGFloat l0[] = {0.0, 0.7, 1.0};
			background_gradient = g0;
			locations = l0;
			numberOfColorsInGradient = 3;
		}
			break;
		case kUIGlossyButtonGradientTypeLinearGlossyStandard:
		{
			static const CGFloat g0[] = {0.7, 1.0, 0.6, 1.0, 0.5, 1.0, 0.45, 1.0};
			static const CGFloat l0[] = {0.0, 0.47, 0.53, 1.0};
			background_gradient = g0;
			locations = l0;
			numberOfColorsInGradient = 4;
		}
			break;
		case kUIGlossyButtonGradientTypeSolid:
		{
			// simplify the code, we create a gradient with one color
			static const CGFloat g0[] = {0.5, 1.0, 0.5, 1.0};
			background_gradient = g0;
			locations = nil;
			numberOfColorsInGradient = 2;
		}
			break;
			
		default:
			break;
	}
}

- (UIBezierPath *) pathForButton : (CGFloat) inset {
	CGFloat radius = _buttonCornerRadius - inset;
	if (radius<0.0) radius = 0.0;
    CGRect rr = UIEdgeInsetsInsetRect(self.bounds, _buttonInsets);
	return [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rr, inset, inset) cornerRadius:radius];
}

- (void)drawRect:(CGRect)rect {
    UIColor *color = _tintColor;
    if (![self isEnabled]) {
        if (_disabledColor) color = _disabledColor;
        else color = [UIColor lightGrayColor];
    }
    if (color==nil) color = [UIColor whiteColor];

	// if the background is transparent, we draw on a image
	// and copy the image to the context with alpha
	BOOL drawOnImage = _backgroundOpacity<1.0;
	
	if (drawOnImage) {
		RetinaAwareUIGraphicsBeginImageContext(self.bounds.size);		
	}
	
	CGContextRef ref = UIGraphicsGetCurrentContext();
    
    BOOL isSelected = [self isHighlighted];
	CGContextSaveGState(ref);
	if (_buttonBorderWidth>0.0) {
		UIColor *color;
		if ([self isEnabled]) color = _borderColor; 
		else {
			color = _disabledBorderColor;
			if (color==nil) color = _borderColor;
		}
		if (color == nil) color = [UIColor darkGrayColor];
		[self strokeButton : ref color : color isSelected: isSelected];
	}
  	[self drawTintColorButton : ref tintColor : color isSelected: isSelected];
	CGContextRestoreGState(ref);
	
	if (drawOnImage) {
		UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		[i drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:_backgroundOpacity];
	}
	
    [super drawRect: rect];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"highlighted"] || [keyPath isEqualToString:@"enabled"]) {
        [self setNeedsDisplay];
    }
}


#pragma -

- (void) strokeButton : (CGContextRef)context color : (UIColor *)color isSelected : (BOOL) isSelected {
	switch (_strokeType) {
        case kUIGlossyButtonStrokeTypeNone:
            break;
		case kUIGlossyButtonStrokeTypeSolid:
			// simple solid border
			CGContextAddPath(context, [self pathForButton : 0.0f].CGPath);
			[color setFill];
			CGContextFillPath(context);	
			break;
		case kUIGlossyButtonStrokeTypeGradientFrame:
			// solid border with gradient outer frame
		{
			CGRect rect = self.bounds;
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
			CGFloat strokeComponents[] = {    
				0.25f, 1.0f, 1.0f, 1.0f
			};
			
            UIBezierPath *outerPath = [self pathForButton : 0.0f]; 
			CGContextAddPath(context, outerPath.CGPath);
			[color setFill];
			CGContextFillPath(context);				
                        
            // stroke the gradient in 1 pixels using overlay so that still keep the stroke color
			CGContextSaveGState(context);
            CGContextAddPath(context, outerPath.CGPath);
            CGContextAddPath(context, [self pathForButton : 1.0f].CGPath);
			CGContextEOClip(context);
            CGContextSetBlendMode(context, kCGBlendModeOverlay);
			
			CGGradientRef strokeGradient = CGGradientCreateWithColorComponents(colorSpace, strokeComponents, NULL, 2);	
			CGContextDrawLinearGradient(context, strokeGradient, CGPointMake(0, CGRectGetMinY(rect)), CGPointMake(0,CGRectGetMaxY(rect)), 0);
			CGGradientRelease(strokeGradient);
			CGColorSpaceRelease(colorSpace);
            
			CGContextRestoreGState(context);
		}
			break;
		case kUIGlossyButtonStrokeTypeInnerBevelDown:
		{
			CGContextSaveGState(context);
			CGPathRef path = [self pathForButton: 0.0f].CGPath;
			CGContextAddPath(context, path);
			CGContextClip(context);
			[[UIColor colorWithWhite:0.9f alpha:1.0f] setFill];
			CGContextAddPath(context, path);
			CGContextFillPath(context);				
            
            CGFloat highlightWidth = _buttonBorderWidth / 4.0f;
            if (highlightWidth<0.5f) highlightWidth = 0.5f;
            else if (highlightWidth>2.0f) highlightWidth = 2.0f;
			CGPathRef innerPath = [self pathForButton: highlightWidth].CGPath;
            CGContextTranslateCTM(context, 0.0f, -highlightWidth);
			[color setFill];
			CGContextAddPath(context, innerPath);
			CGContextFillPath(context);

			CGContextRestoreGState(context);
		}
			break;
		case kUIGlossyButtonStrokeTypeBevelUp:
		{
			CGRect rect = self.bounds;
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
			const CGFloat *strokeComponents;
            const CGFloat *l0;
            if (_invertGraidentOnSelected && isSelected) {
                const CGFloat s[] = {0.2, 1, 0.5, 1, 0.6, 1};
                const CGFloat l[] = {0.0, 0.1, 1.0};
                strokeComponents = s; l0 = l;
            }
            else {
                const CGFloat s[] = {0.9, 1, 0.5, 1, 0.2, 1};
                const CGFloat l[] = {0.0, 0.1, 1.0};
                strokeComponents = s; l0 = l;
            }
			
			CGContextAddPath(context, [self pathForButton : 0.0f].CGPath);
			CGContextClip(context);
			
			CGGradientRef strokeGradient = CGGradientCreateWithColorComponents(colorSpace, strokeComponents, l0, 3);	
            CGContextDrawLinearGradient(context, strokeGradient, CGPointMake(0, CGRectGetMinY(rect)), CGPointMake(0,CGRectGetMaxY(rect)), 0);
			CGGradientRelease(strokeGradient);
			CGColorSpaceRelease(colorSpace);

            [color set];
            UIRectFillUsingBlendMode(rect, kCGBlendModeOverlay);

			CGContextFillPath(context);				
		}
			break;
		default:
			break;
	}
}

- (void) addShading : (CGContextRef) context type : (UIGlossyButtonExtraShadingType)type rect : (CGRect) rect colorSpace : (CGColorSpaceRef) colorSpace {
	switch (type) {
		case kUIGlossyButtonExtraShadingTypeRounded:
		{
			
			CGPathRef shade = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(rect.origin.x, rect.origin.y-_buttonCornerRadius, rect.size.width, _buttonCornerRadius+rect.size.height/2.0) cornerRadius:_buttonCornerRadius].CGPath;
			CGContextAddPath(context, shade);
			CGContextClip(context);
			const CGFloat strokeComponents[4] = {0.80, 1, 0.55, 1};
			CGGradientRef strokeGradient = CGGradientCreateWithColorComponents(colorSpace, strokeComponents, NULL, 2);	
			CGContextDrawLinearGradient(context, strokeGradient, CGPointMake(0, CGRectGetMinY(rect)), CGPointMake(0,rect.origin.y + rect.size.height * 0.7), 0);
			CGGradientRelease(strokeGradient);			
		}
			break;
		case kUIGlossyButtonExtraShadingTypeAngleLeft:
		{
			CGRect roundRect = CGRectMake(rect.origin.x-rect.size.width * 2, rect.origin.y - rect.size.height * 3.33, rect.size.width*4.0f, rect.size.height*4.0f);			
			CGContextAddEllipseInRect(context, roundRect);
			CGContextClip(context);
			const CGFloat strokeComponents[4] = {0.80, 1, 0.55, 1};
			CGGradientRef strokeGradient = CGGradientCreateWithColorComponents(colorSpace, strokeComponents, NULL, 2);	
			CGContextDrawLinearGradient(context, strokeGradient, CGPointMake(rect.origin.x, rect.origin.y), CGPointMake(rect.origin.x+rect.size.width / 2.0, rect.origin.y + rect.size.height * 0.7), 0);
			CGGradientRelease(strokeGradient);			
		}
			break;
		case kUIGlossyButtonExtraShadingTypeAngleRight:
		{
			CGRect roundRect = CGRectMake(rect.origin.x-rect.size.width, rect.origin.y - rect.size.height * 3.33, rect.size.width*4.0f, rect.size.height*4.0f);			
			CGContextAddEllipseInRect(context, roundRect);
			CGContextClip(context);
			const CGFloat strokeComponents[4] = {0.80, 1, 0.55, 1};
			CGGradientRef strokeGradient = CGGradientCreateWithColorComponents(colorSpace, strokeComponents, NULL, 2);	
			CGContextDrawLinearGradient(context, strokeGradient, CGPointMake(rect.origin.x+rect.size.width, rect.origin.y), CGPointMake(rect.origin.x+rect.size.width / 2.0, rect.origin.y + rect.size.height * 0.7), 0);
			CGGradientRelease(strokeGradient);			
		}
			break;
		default:
			break;
	}
}

- (void) drawTintColorButton : (CGContextRef)context tintColor : (UIColor *) tintColor isSelected : (BOOL) isSelected {
	CGRect rect = self.bounds;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	if (_innerBorderWidth > 0.0) {
		// STROKE GRADIENT
		CGContextAddPath(context, [self pathForButton : _buttonBorderWidth].CGPath);
		CGContextClip(context);
		
		CGContextSaveGState(context);
		
		const CGFloat strokeComponents[4] = {0.55, 1, 0.40, 1};
		CGGradientRef strokeGradient = CGGradientCreateWithColorComponents(colorSpace, strokeComponents, NULL, 2);	
		CGContextDrawLinearGradient(context, strokeGradient, CGPointMake(0, CGRectGetMinY(rect)), CGPointMake(0,CGRectGetMaxY(rect)), 0);
		CGGradientRelease(strokeGradient);		
	}	
	
	// FILL GRADIENT	
	CGRect fillRect = CGRectInset(rect,_buttonBorderWidth + _innerBorderWidth, _buttonBorderWidth + _innerBorderWidth);
	CGContextAddPath(context, [self pathForButton : _buttonBorderWidth + _innerBorderWidth].CGPath);
	CGContextClip(context);
	
	CGGradientRef fillGradient = CGGradientCreateWithColorComponents(colorSpace, background_gradient, locations, numberOfColorsInGradient);	
    if (_invertGraidentOnSelected && isSelected) {
        CGContextDrawLinearGradient(context, fillGradient, CGPointMake(0, CGRectGetMaxY(fillRect)), CGPointMake(0,CGRectGetMinY(fillRect)), 0);    
    }
    else {
        CGContextDrawLinearGradient(context, fillGradient, CGPointMake(0, CGRectGetMinY(fillRect)), CGPointMake(0,CGRectGetMaxY(fillRect)), 0);
    }
	CGGradientRelease(fillGradient);
	
	if (_extraShadingType != kUIGlossyButtonExtraShadingTypeNone) {
		// add additional glossy effect
		CGContextSaveGState(context);
		CGContextSetBlendMode(context, kCGBlendModeLighten);
		[self addShading:context type:_extraShadingType rect:fillRect colorSpace:colorSpace];
		CGContextRestoreGState(context);
	}
	
	CGColorSpaceRelease(colorSpace);
	
	if (_innerBorderWidth > 0.0) {
		CGContextRestoreGState(context);
	}
	
	[tintColor set];
	UIRectFillUsingBlendMode(rect, kCGBlendModeOverlay);
	
	if (isSelected) {
		[[UIColor lightGrayColor] set];
		UIRectFillUsingBlendMode(rect, kCGBlendModeMultiply);
	}
}

#pragma pre-defined buttons

- (void) setActionSheetButtonWithColor : (UIColor*) color {
	self.tintColor = color;
	[self setGradientType:kUIGlossyButtonGradientTypeLinearGlossyStandard];
	[self.titleLabel setFont: [UIFont boldSystemFontOfSize: 17.0f]];
	[self useWhiteLabel: NO];
	self.buttonCornerRadius = 8.0f;
	self.strokeType = kUIGlossyButtonStrokeTypeGradientFrame;
	self.buttonBorderWidth = 3.0;
	self.borderColor = [UIColor colorWithWhite:0.2f alpha:0.8f];
	[self setNeedsDisplay];
}

- (void) setNavigationButtonWithColor : (UIColor*) color {
	self.tintColor = color;
	self.disabledBorderColor = [UIColor lightGrayColor];
	[self setGradientType:kUIGlossyButtonGradientTypeLinearGlossyStandard];
	[self.titleLabel setFont: [UIFont boldSystemFontOfSize: 12.0f]];
	[self useWhiteLabel: NO];
	[self setTitleColor:[UIColor colorWithWhite:0.5 alpha:1.0] forState:UIControlStateDisabled];
	self.buttonCornerRadius = 4.0f;
	self.strokeType = kUIGlossyButtonStrokeTypeInnerBevelDown;
	self.buttonBorderWidth = 1.0;
	self.innerBorderWidth = 0.0;
	[self setNeedsDisplay];
}

+(UIGlossyButton *)cptDefaultNavBarGlossyButtonWithTitle:(NSString *)title withHighlight:(BOOL)highlight maximumButtonWidth:(CGFloat)maxWidth;
{
    // Define initial font size
    CGFloat fontSize;
    UIFont *font;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        fontSize = 15.0f;
    } else {
        fontSize = 12.0f;
    }
    
    // If there is a min width, iterate down to fit it
    if (maxWidth > 0.0f) {
        CGFloat trialWidth;
        do {
            font = [UIFont fontWithName:@"Arial-BoldMT" size:fontSize];
            CGSize trialSize = [title sizeWithFont:font];
            trialWidth = trialSize.width + 14.0f;
            fontSize -= 1.0f;
        } while (trialWidth > maxWidth);
    } else {
        font = [UIFont fontWithName:@"Arial-BoldMT" size:fontSize];
    }
    
    CGSize labelSize = [title sizeWithFont:font];
    labelSize.width += 14.0f;
    
    UIGlossyButton *newButton = [[UIGlossyButton alloc] initWithFrame:CGRectMake(0, 8, roundf(labelSize.width), 28)];
    if (highlight) {
        newButton.tintColor = [UIColor cptPrimaryColorSelected];
        newButton.borderColor = [UIColor cptPrimaryColorSelected];
    } else {
        newButton.tintColor = [UIColor cptPrimaryColor];
        newButton.borderColor = [UIColor cptPrimaryColor];
    }
    newButton.tag = 0;
	[newButton useWhiteLabel: YES];
	newButton.backgroundOpacity = 1.0;
	newButton.innerBorderWidth = 0.0f;
	newButton.buttonBorderWidth = 2.0f;
	newButton.buttonCornerRadius = 6.0f;
	newButton.strokeType = kUIGlossyButtonStrokeTypeBevelUp;
	[newButton setGradientType: kUIGlossyButtonGradientTypeLinearGlossyStandard];
	[newButton setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    [newButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [newButton.titleLabel setMinimumScaleFactor:0.1];
    [newButton.titleLabel setFont:font];
    
    if (highlight) {
        [newButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [newButton.titleLabel setShadowOffset:CGSizeMake(1.0f, 1.0f)];
    }
    newButton.disabledBorderColor = [UIColor grayColor];
    newButton.disabledColor = [UIColor grayColor];
    
    [newButton setTitle:title forState:UIControlStateNormal];
    
    [newButton setPlaySoundWhenPressed:YES];
    
    return newButton;
}

+(UIGlossyButton *)cptDefaultNavBarGlossyButtonWithTitle:(NSString *)title withHighlight:(BOOL)highlight;
{
    return [UIGlossyButton cptDefaultNavBarGlossyButtonWithTitle:title withHighlight:highlight maximumButtonWidth:0.0f];
}

-(void)applyCPTDefaultGlossyButtonFeaturesWithTitle:(NSString *)title withHighlight:(BOOL)highlight;
{
    if (highlight) {
        self.tintColor = [UIColor cptPrimaryColorSelected];
        self.borderColor = [UIColor cptPrimaryColorSelected];
    } else {
        self.tintColor = [UIColor cptPrimaryColor];
        self.borderColor = [UIColor cptPrimaryColor];
    }
    self.tag = 0;
	[self useWhiteLabel: YES];
	self.backgroundOpacity = 1.0;
	self.innerBorderWidth = 0.0f;
	self.buttonBorderWidth = 2.0f;
	self.buttonCornerRadius = 6.0f;
	self.strokeType = kUIGlossyButtonStrokeTypeBevelUp;
	[self setGradientType: kUIGlossyButtonGradientTypeLinearGlossyStandard];
	[self setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    [self.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [self.titleLabel setMinimumScaleFactor:0.1];
    UIFont *font = [UIFont fontWithName:@"Arial-BoldMT" size:15.0f];
    [self.titleLabel setFont:font];
    
    if (highlight) {
        [self.titleLabel setShadowColor:[UIColor blackColor]];
        [self.titleLabel setShadowOffset:CGSizeMake(1.0f, 1.0f)];
    }
    self.disabledBorderColor = [UIColor grayColor];
    self.disabledColor = [UIColor grayColor];
    
    [self setTitle:title forState:UIControlStateNormal];
    
    [self setPlaySoundWhenPressed:YES];
}

-(void)applyCPTDefaultGlossyButtonFeaturesWithTitle:(NSString *)title tintColor:(UIColor *)aTintColor borderColor:(UIColor *)aBorderColor disabledColor:(UIColor *)aDisabledColor disabledBorderColor:(UIColor *)aDisabledBorderColor;
{
    UIFont *font = [UIFont fontWithName:@"Arial-BoldMT" size:15.0f];
    
    self.titleLabel.font = font;
    self.tintColor = aTintColor;
    self.titleLabel.text = title;
    [self.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [self.titleLabel setMinimumScaleFactor:0.4];
	[self useWhiteLabel: YES];
	self.backgroundOpacity = 1.0;
	self.innerBorderWidth = 0.0f;
	self.buttonBorderWidth = 3.0f;
	self.buttonCornerRadius = 8.0f;
    self.borderColor = aBorderColor;
    self.disabledColor = aDisabledColor;
    self.disabledBorderColor = aDisabledBorderColor;
	self.strokeType = kUIGlossyButtonStrokeTypeGradientFrame;
	[self setGradientType: kUIGlossyButtonGradientTypeSolid];
	[self setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
}

+(UIGlossyButton *)glossyButtonWithTitle:(NSString *)title image:(UIImage *)image highlighted:(BOOL)highlighted forTarget:(id)target selector:(SEL)selector forControlEvents:(UIControlEvents)controlEvents maximumButtonWidth:(CGFloat)maxWidth;
{
    UIGlossyButton *glossyButton;
    CGFloat finalButtonHeight = 38.0f;
    if (nil != title && nil == image) {
        glossyButton = [UIGlossyButton cptDefaultNavBarGlossyButtonWithTitle:title withHighlight:highlighted maximumButtonWidth:maxWidth];
        [glossyButton setTag:777];
        [glossyButton addTarget:target action:selector forControlEvents:controlEvents];
        CGRect buttonRect = [glossyButton frame];
        CGRect finalRect = CGRectMake(0, 0, buttonRect.size.width, finalButtonHeight);
        [glossyButton setFrame:finalRect];
        
    } else if (nil != image && nil == title) {
        
        CGFloat finalImageHeight = 30.0f;
        CGFloat extraImageWidthSpacing = 10.0f;
        CGFloat scale = finalImageHeight / image.size.height;
        CGRect imageViewRect = CGRectMake(roundf(extraImageWidthSpacing/2.0f), 0, roundf(scale * image.size.width), finalImageHeight);
        CGRect buttonRect = CGRectMake(0, 0, imageViewRect.size.width + extraImageWidthSpacing, finalButtonHeight);
        
        glossyButton = [UIGlossyButton cptDefaultNavBarGlossyButtonWithTitle:@"" withHighlight:highlighted];
        [glossyButton addTarget:target action:selector forControlEvents:controlEvents];
        [glossyButton setTag:777];
        [glossyButton setFrame:buttonRect];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewRect];
        [imageView setBackgroundColor:[UIColor clearColor]];
        [imageView setImage:image];
        [imageView setContentScaleFactor:[[UIScreen mainScreen] scale]];
        [imageView setTag:778];
        [glossyButton addSubview:imageView];
        [imageView setCenter:glossyButton.center];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        [imageView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth)];
        
    } else if (nil != image && nil != title) {
        
        // Button with image to left of text
        
        // Determine rect required for the image
        CGFloat finalImageHeight = 30.0f;
        CGFloat extraImageWidthSpacing = 10.0f;
        CGFloat scale = finalImageHeight / image.size.height;
        CGRect imageViewRect = CGRectMake(roundf(extraImageWidthSpacing/2.0f), roundf((finalButtonHeight - finalImageHeight)/2), roundf(scale * image.size.width), finalImageHeight);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageViewRect];
        [imageView setBackgroundColor:[UIColor clearColor]];
        [imageView setContentScaleFactor:[[UIScreen mainScreen] scale]];
        [imageView setImage:image];
        [imageView setTag:778];
        
        if (maxWidth > 0.0f) {
            CGFloat widthRemainingForTitle = MAX(0.0f,(maxWidth - imageViewRect.size.width));
            glossyButton = [UIGlossyButton cptDefaultNavBarGlossyButtonWithTitle:title withHighlight:highlighted maximumButtonWidth:widthRemainingForTitle];
        } else {
            glossyButton = [UIGlossyButton cptDefaultNavBarGlossyButtonWithTitle:title withHighlight:highlighted];
        }
        
        // Create the initial button with just the text
        [glossyButton setTag:777];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:glossyButton.titleLabel.frame];
        [titleLabel setText:glossyButton.titleLabel.text];
        [titleLabel setTextAlignment:glossyButton.titleLabel.textAlignment];
        [titleLabel setTextColor:glossyButton.titleLabel.textColor];
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [titleLabel setFont:glossyButton.titleLabel.font];
        
        CGRect titleLabelRect = CGRectMake(imageViewRect.size.width+(extraImageWidthSpacing/2.0f), roundf((finalButtonHeight-titleLabel.bounds.size.height)/2), roundf(titleLabel.bounds.size.width+(extraImageWidthSpacing/2.0f)), titleLabel.bounds.size.height);
        titleLabel.frame = titleLabelRect;
        
        CGRect combinedRect = CGRectUnion(imageViewRect, titleLabelRect);
        UIView *combinedView = [[UIView alloc] initWithFrame:combinedRect];
        [combinedView setBackgroundColor:[UIColor clearColor]];
        [combinedView addSubview:imageView];
        [combinedView addSubview:titleLabel];
        [combinedView setUserInteractionEnabled:NO];
        [combinedView setExclusiveTouch:NO];
        
        CGRect buttonRect = CGRectMake(0, 0, (combinedRect.size.width + extraImageWidthSpacing), finalButtonHeight);
        [glossyButton setTitle:@"" forState:UIControlStateNormal];
        [glossyButton setFrame:buttonRect];
        [glossyButton addTarget:target action:selector forControlEvents:controlEvents];
        
        [glossyButton addSubview:imageView];
        [glossyButton addSubview:titleLabel];
        
    } else {
        // Ooops. Should have caught in prior statements, but if you go here, return a blank button so something can be shown
        glossyButton = [UIGlossyButton cptDefaultNavBarGlossyButtonWithTitle:@"" withHighlight:highlighted maximumButtonWidth:maxWidth];
        [glossyButton setTag:777];
    }
    [glossyButton setPlaySoundWhenPressed:YES];
    
//    DDLogVerbose(@"GlossyButton %@ has frame %@",glossyButton,NSStringFromCGRect(glossyButton.frame));
    
    return glossyButton;
}

+(UIGlossyButton *)glossyButtonWithTitle:(NSString *)title image:(UIImage *)image highlighted:(BOOL)highlighted forTarget:(id)target selector:(SEL)selector forControlEvents:(UIControlEvents)controlEvents;
{
    return [UIGlossyButton glossyButtonWithTitle:title image:image highlighted:highlighted forTarget:target selector:selector forControlEvents:controlEvents maximumButtonWidth:0.0f];
}

@end


@implementation UIGNavigationButton

@synthesize leftArrow = _leftArrow;

- (UIBezierPath *) pathForButton : (CGFloat) inset {
    CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, _buttonInsets);
	CGRect rr = CGRectInset(bounds, inset, inset);
	CGFloat radius = _buttonCornerRadius - inset;
	if (radius<0.0) radius = 0.0;
	CGFloat arrowWidth = round(bounds.size.height * 0.30);
	CGFloat radiusOffset = 0.29289321 * radius;
    CGFloat extraHeadInset = 0.01118742 * inset;
	if (_leftArrow) {
		CGRect rr1 = CGRectMake(arrowWidth+rr.origin.x+extraHeadInset, rr.origin.y, rr.size.width-arrowWidth-extraHeadInset, rr.size.height);
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rr1 cornerRadius:radius];
		[path moveToPoint: CGPointMake(rr.origin.x+extraHeadInset, rr.origin.y + rr.size.height / 2.0)];
		[path addLineToPoint:CGPointMake(rr.origin.x+arrowWidth+radiusOffset+extraHeadInset, rr.origin.y+radiusOffset)];
		[path addLineToPoint:CGPointMake(rr.origin.x+arrowWidth+radiusOffset+extraHeadInset, rr.origin.y+rr.size.height-radiusOffset)];
		[path closePath];
		return path;
	}
	else {
		CGRect rr1 = CGRectMake(rr.origin.x, rr.origin.y, rr.size.width-arrowWidth-extraHeadInset, rr.size.height);
		UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rr1 cornerRadius:radius];
		[path moveToPoint: CGPointMake(rr.origin.x + rr.size.width - extraHeadInset, rr.origin.y + rr.size.height / 2.0)];
		[path addLineToPoint:CGPointMake(rr.origin.x+ rr.size.width - arrowWidth - radiusOffset - extraHeadInset, rr.origin.y+rr.size.height-radiusOffset)];
		[path addLineToPoint:CGPointMake(rr.origin.x+ rr.size.width - arrowWidth - radiusOffset - extraHeadInset, rr.origin.y+radiusOffset)];
		[path closePath];
		return path;
	}
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
	CGFloat arrowWidth = round(self.bounds.size.height * 0.30);
	if (_leftArrow) {
		contentRect.origin.x += arrowWidth; contentRect.size.width -= arrowWidth;
	}
	else {
		contentRect.size.width -= arrowWidth;
	}
	return [super titleRectForContentRect: contentRect];
}

@end

@implementation UIGBadgeButton

@synthesize numberOfEdges;
@synthesize innerRadiusRatio;

- (void) setupSelf {
	[super setupSelf];
	numberOfEdges = 24;
	innerRadiusRatio = 0.75;
}

- (UIBezierPath *) pathForButton : (CGFloat) inset {
    CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, _buttonInsets);
	CGPoint center = CGPointMake(bounds.size.width/2.0, bounds.size.height/2.0);
	CGFloat outerRadius = MIN(bounds.size.width, bounds.size.height) / 2.0 - inset;
	CGFloat innerRadius = outerRadius * innerRadiusRatio;
	CGFloat angle = M_PI * 2.0 / (numberOfEdges * 2);
	UIBezierPath *path = [UIBezierPath bezierPath];
	for (NSInteger cc=0; cc<numberOfEdges; cc++) {
		CGPoint p0 = CGPointMake(center.x + outerRadius * cos(angle * (cc*2)), center.y + outerRadius * sin(angle * (cc*2)));
		CGPoint p1 = CGPointMake(center.x + innerRadius * cos(angle * (cc*2+1)), center.y + innerRadius * sin(angle * (cc*2+1)));
		
		if (cc==0) {
			[path moveToPoint: p0];
		}
		else {
			[path addLineToPoint: p0];
		}
		[path addLineToPoint: p1];
	}
	[path closePath];
	return path;
}

@end

@implementation UIGlossyBarButtonItem

+(UIGlossyBarButtonItem *)glossyBarButtonItemWithTitle:(NSString *)title image:(UIImage *)image highlighted:(BOOL)highlighted forTarget:(id)target selector:(SEL)selector forControlEvents:(UIControlEvents)controlEvents maximumButtonWidth:(CGFloat)maxWidth;
{
    UIGlossyButton *glossyButton = [UIGlossyButton glossyButtonWithTitle:title image:image highlighted:highlighted forTarget:target selector:selector forControlEvents:controlEvents maximumButtonWidth:maxWidth];
    
    CGFloat finalButtonHeight = 34.0f;
    CGRect buttonRect = CGRectMake(0, 0, (glossyButton.frame.size.width + 0.0f), finalButtonHeight);
    UIView *containerView = [[UIView alloc] initWithFrame:buttonRect];
    [containerView setBackgroundColor:[UIColor clearColor]];
    [containerView addSubview:glossyButton];
    [glossyButton setCenter:containerView.center];
    
//    DDLogVerbose(@"GlossyButton container view frame = %@",NSStringFromCGRect(containerView.frame));
    return [[UIGlossyBarButtonItem alloc] initWithCustomView:containerView];
}

+(UIGlossyBarButtonItem *)glossyBarButtonItemWithTitle:(NSString *)title image:(UIImage *)image highlighted:(BOOL)highlighted forTarget:(id)target selector:(SEL)selector forControlEvents:(UIControlEvents)controlEvents;
{
    UIGlossyBarButtonItem *barButtonItem = [UIGlossyBarButtonItem glossyBarButtonItemWithTitle:title image:image highlighted:highlighted forTarget:target selector:selector forControlEvents:controlEvents maximumButtonWidth:0.0f];
//    DDLogVerbose(@"BarButtonItem = %@ ; CustomView = %@",barButtonItem,barButtonItem.customView);
    return barButtonItem;
}

-(void)setEnabled:(BOOL)enabled;
{
    [super setEnabled:enabled];
    if (nil != [[self customView] viewWithTag:777]) {
        [(UIGlossyButton *)[[self customView] viewWithTag:777] setEnabled:enabled];
    }
    if (nil != [[self customView] viewWithTag:778]) {
        CGFloat alpha = 1.0f;
        if (!enabled) {
            alpha = 0.5f;
        }
        [(UIImageView *)[[self customView] viewWithTag:778] setAlpha:alpha];
    }
}

@end
