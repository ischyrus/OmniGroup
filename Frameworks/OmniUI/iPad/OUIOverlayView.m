// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniUI/OUIOverlayView.h>

RCS_ID("$Id$");


@interface OUIOverlayView (/*Private*/)
- (void)_hideOverlayEffectDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
@end


@implementation OUIOverlayView

#pragma mark -
#pragma mark Convenience methods

+ (UIImage *)backgroundImage;
{
    static UIImage *_backgroundImage = nil;
    if (!_backgroundImage) {
        UIImage *image = [UIImage imageNamed:@"OUIOverlayBackground.png"];
        _backgroundImage = [[image stretchableImageWithLeftCapWidth:7 topCapHeight:7] retain];
    }
    return _backgroundImage;
}

+ (OUIOverlayView *)sharedTemporaryOverlay;
{
    static OUIOverlayView *_overlayView = nil;

    if (!_overlayView) {
        _overlayView = [[OUIOverlayView alloc] initWithFrame:CGRectMake(300, 100, 200, 26)];
    }
    
    return _overlayView;
}

+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string avoidingTouchPoint:(CGPoint)touchPoint;
{
    OUIOverlayView *overlayView = [self sharedTemporaryOverlay];
    
    overlayView.text = string;
    
    if (CGPointEqualToPoint(touchPoint, CGPointZero)) {
        [overlayView useAlignment:OUIOverlayViewAlignmentUpCenter withinBounds:view.bounds];
    } else {
        [overlayView avoidTouchPoint:touchPoint withinBounds:view.bounds];
    }
    
    [overlayView displayTemporarilyInView:view];
}

+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string centeredAtPoint:(CGPoint)touchPoint displayInterval:(NSTimeInterval)displayInterval;
{
    OUIOverlayView *overlayView = [self sharedTemporaryOverlay];
    
    overlayView.text = string;
    
    [overlayView centerAtPoint:touchPoint withOffset:CGPointZero withinBounds:view.bounds];
    
    if (displayInterval) {
        overlayView.messageDisplayInterval = displayInterval;
    }
    
    [overlayView displayTemporarilyInView:view];
}

+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string centeredAbovePoint:(CGPoint)touchPoint displayInterval:(NSTimeInterval)displayInterval;
{
    OUIOverlayView *overlayView = [self sharedTemporaryOverlay];
    
    overlayView.text = string;
    
    [overlayView centerAbovePoint:touchPoint withinBounds:view.bounds];
    
    if (displayInterval) {
        overlayView.messageDisplayInterval = displayInterval;
    }

    [overlayView displayTemporarilyInView:view];
}

+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string positionedForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer displayInterval:(NSTimeInterval)displayInterval;
{
    OUIOverlayView *overlayView = [self sharedTemporaryOverlay];
    
    overlayView.text = string;
    
    [overlayView centerAtPositionForGestureRecognizer:gestureRecognizer inView:view];
    
    if (displayInterval) {
        overlayView.messageDisplayInterval = displayInterval;
    }
    
    [overlayView displayTemporarilyInView:view];
}

+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string alignment:(OUIOverlayViewAlignment)alignment displayInterval:(NSTimeInterval)displayInterval;
{
    OUIOverlayView *overlayView = [self sharedTemporaryOverlay];
    
    overlayView.text = string;
    
    [overlayView useAlignment:alignment withinBounds:view.bounds];
    
    if (displayInterval) {
        overlayView.messageDisplayInterval = displayInterval;
    }
    
    [overlayView displayTemporarilyInView:view];
}

- (void)displayTemporarilyInView:(UIView *)view;
{
    shouldHide = NO;
    
    // If an overlay is already being displayed, replace it and cancel its timer
    if (_overlayTimer) {
        [_overlayTimer invalidate];
        _overlayTimer = nil;
    }
    // If new, fade in the overlay
    else {
        [self displayInView:view];
    }
    
    _overlayTimer = [NSTimer scheduledTimerWithTimeInterval:self.messageDisplayInterval target:self selector:@selector(_temporaryOverlayTimerFired:) userInfo:nil repeats:NO];
}

- (void)_temporaryOverlayTimerFired:(NSTimer *)timer;
{
    _overlayTimer = nil;
    
    [self hide];
}

- (void)displayInView:(UIView *)view;
{    
    shouldHide = NO;
    [self.layer removeAllAnimations];
    
    if (self.superview != view) {
        self.alpha = 0;
        [view addSubview:self];
    }
    
    [UIView beginAnimations:@"RSTemporaryOverlayAnimation" context:NULL];
    {
        //[UIView setAnimationDuration:SELECTION_DELAY];
        self.alpha = 1;
    }
    [UIView commitAnimations];
}

- (void)hide;
{
    [self hideAnimated:YES];
}

- (void)hideAnimated:(BOOL)animated;
{
    if (!animated) {
        // Hide immediately and cancel any timers in progress
        if (_overlayTimer) {
            [_overlayTimer invalidate];
            _overlayTimer = nil;
        }
        shouldHide = YES;
        self.alpha = 0;
        [self _hideOverlayEffectDidStop:nil finished:nil context:NULL];
        return;
    }
    
    // Don't repeat if already in the process of hiding
    if (shouldHide)
        return;
    
    shouldHide = YES;
    
    [UIView beginAnimations:@"RSTemporaryOverlayAnimation" context:NULL];
    {
        //[UIView setAnimationDuration:SELECTION_DELAY];
        self.alpha = 0;
        
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(_hideOverlayEffectDidStop:finished:context:)];
    }
    [UIView commitAnimations];
}

- (void)_hideOverlayEffectDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
{
    // Cancel if a new overlay was created
    if (_overlayTimer)
        return;
    
    // Cancel if the overlay was told to show before finishing hiding
    if (!shouldHide)
        return;
    
    [self removeFromSuperview];
}

- (BOOL)isVisible;
{
    return self.superview && self.alpha == 1;
}


#pragma mark -
#pragma mark alloc/init

- (id)initWithFrame:(CGRect)aRect;
{
    if (!(self = [super initWithFrame:aRect]))
        return nil;
    
    self.userInteractionEnabled = NO;
    self.opaque = NO;
    
    [self resetDefaults];
    
    _cachedSuggestedSize = CGSizeZero;
    
    return self;
}

- (void)dealloc;
{
    [_font release];
    self.text = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Class methods

- (void)resetDefaults;
{
    _font = [[UIFont boldSystemFontOfSize:16] retain];
    _borderSize = CGSizeMake(8, 8);
    _messageDisplayInterval = 1.5;
    
    _cachedSuggestedSize = CGSizeZero;
}

@synthesize text = _text;
- (void)setText:(NSString *)string;
{
    if ([_text isEqualToString:string])
        return;
    
    [_text release];
    _text = [string retain];
    
    _cachedSuggestedSize = CGSizeZero;
    [self setNeedsDisplay];
    
}

- (CGFloat)fontSize;
{
    return [_font pointSize];
}
- (void)setFontSize:(CGFloat)newSize;
{
    if (newSize == [_font pointSize]) {
        return;
    }
    
    UIFont *newFont = [_font fontWithSize:newSize];
    [_font release];
    _font = newFont;
}

@synthesize borderSize = _borderSize;
@synthesize messageDisplayInterval = _messageDisplayInterval;

- (void)setFrame:(CGRect)newFrame;
{
    if ([self superview]) {
        CGPoint origin = [[self superview] convertPoint:newFrame.origin toView:nil];
        origin.x = rint(origin.x);
        origin.y = rint(origin.y);
        origin = [[self superview] convertPoint:origin fromView:nil];
        newFrame.origin = origin;
    }

    if (!CGSizeEqualToSize(self.frame.size, newFrame.size)) {
        [self setNeedsDisplay];
    }
    
    [super setFrame:newFrame];
}

- (CGSize)suggestedSize;
{
    if (_cachedSuggestedSize.width) {
        return _cachedSuggestedSize;
    }

    //NSLog(@"########### Calculating size");
    CGSize textSize = [self.text sizeWithFont:_font];
    CGSize suggestedSize = CGSizeMake(textSize.width + self.borderSize.width*2, textSize.height + self.borderSize.height*2);
    suggestedSize.width += 1;  // Just in case the -sizeWithFont result is off slightly
    _cachedSuggestedSize = suggestedSize;
    return _cachedSuggestedSize;
}

- (void)useSuggestedSize;
{
    CGSize suggestedSize = [self suggestedSize];
    
    CGRect rect = [self bounds];
    rect.size = suggestedSize;
    self.bounds = rect;
    
    [self setFrame:self.frame];  // pixel-align
}

- (void)avoidTouchPoint:(CGPoint)touchPoint withinBounds:(CGRect)superBounds;
{
    CGRect upperLeftRect = CGRectMake(0, 0, superBounds.size.width/2, superBounds.size.height/2);
    //NSLog(@"upperLeftRect: %@; touchPoint: %@", NSStringFromCGRect(upperLeftRect), NSStringFromCGPoint(touchPoint));
    
    CGRect newFrame;
    CGSize suggestedSize = [self suggestedSize];
    if (CGRectContainsPoint(upperLeftRect, touchPoint)) {
        CGFloat x = superBounds.size.width - 100 - suggestedSize.width;
        newFrame = CGRectMake(x, 70, suggestedSize.width, suggestedSize.height);
    } else {
        newFrame = CGRectMake(100, 70, suggestedSize.width, suggestedSize.height);
    }
    
    self.frame = newFrame;
}

- (void)centerAtPoint:(CGPoint)touchPoint withOffset:(CGPoint)offset withinBounds:(CGRect)superBounds;
{
    CGSize suggestedSize = [self suggestedSize];
    
    CGPoint topLeft = touchPoint;
    topLeft.x -= suggestedSize.width/2;
    topLeft.y -= suggestedSize.height;
    
    // Adjust by offset amount
    topLeft.x += offset.x;
    topLeft.y += offset.y;
    
    CGRect newFrame = CGRectMake(topLeft.x, topLeft.y, suggestedSize.width, suggestedSize.height);
    
    // Don't go past edges
    if (newFrame.origin.y < OUIOverlayViewDistanceFromTopEdge)
        newFrame.origin.y = OUIOverlayViewDistanceFromTopEdge;
    if (newFrame.origin.x < OUIOverlayViewDistanceFromHorizontalEdge)
        newFrame.origin.x = OUIOverlayViewDistanceFromHorizontalEdge;
    if (CGRectGetMaxX(newFrame) + OUIOverlayViewDistanceFromHorizontalEdge > CGRectGetMaxX(superBounds))
        newFrame.origin.x = CGRectGetMaxX(superBounds) - suggestedSize.width - OUIOverlayViewDistanceFromHorizontalEdge;
    
    newFrame = CGRectIntegral(newFrame);
    
    self.frame = newFrame;
}

- (void)centerAbovePoint:(CGPoint)touchPoint withinBounds:(CGRect)superBounds;
{
    [self centerAtPoint:touchPoint withOffset:CGPointMake(0, -80) withinBounds:superBounds];
}

- (void)useAlignment:(OUIOverlayViewAlignment)alignment withinBounds:(CGRect)superBounds;
{
    CGSize suggestedSize = [self suggestedSize];
    
    CGFloat horizontalCenter = CGRectGetMidX(superBounds);
    CGFloat left = horizontalCenter - suggestedSize.width/2;
    
    CGFloat top = OUIOverlayViewDistanceFromTopEdge;
    switch (alignment) {
        case OUIOverlayViewAlignmentMidCenter:
            top = CGRectGetMidY(superBounds);
            top -= suggestedSize.height/2;
            break;
        case OUIOverlayViewAlignmentDownCenter:
            top = CGRectGetMaxY(superBounds) - OUIOverlayViewDistanceFromTopEdge - suggestedSize.height;
            break;
        default:
            break;
    }
    
    CGRect newFrame = CGRectMake(left, top, suggestedSize.width, suggestedSize.height);
    newFrame = CGRectIntegral(newFrame);
    
    self.frame = newFrame;
}

- (CGPoint)positionForTwoTouchGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer inView:(UIView *)stableView;
// Imitate the behavior of the iWork apps, which position the zoom overlay a certain distance perpendicularly from the line between the pinching touches.
{
    if ([gestureRecognizer numberOfTouches] < 2) {
        return CGPointZero;
    }
    
    CGPoint touch1 = [gestureRecognizer locationOfTouch:0 inView:stableView];
    CGPoint touch2 = [gestureRecognizer locationOfTouch:1 inView:stableView];
    CGPoint center = CGPointMake((touch1.x + touch2.x)/2, (touch1.y + touch2.y)/2);
    
    // If the touches are roughly vertical, use the median point rather than guessing which side the hand is on.
    if (fabs(touch1.x - touch2.x) < 20) {
        return center;
    }
    
    CGPoint touchVector = CGPointMake(touch2.x - touch1.x, touch2.y - touch1.y);
    
    // Make sure the vector is pointing up
    if (touchVector.y > 0) {
        touchVector.x *= -1;
        touchVector.y *= -1;
    }
    
    // Normalize length
    CGFloat length = hypotf(touchVector.x, touchVector.y);
    CGFloat lengthFactor = OUIOverlayViewPerpendicularDistanceFromTwoTouches/length;
    CGPoint vNorm = CGPointMake(touchVector.x*lengthFactor, touchVector.y*lengthFactor);
    
    // Make perpendicular and pointing up
    CGPoint vPerp = CGPointMake(vNorm.y, -vNorm.x);
    if (vPerp.y > 0) {
        vPerp.x *= -1;
        vPerp.y *= -1;
    }
    
    // Calculate actual point
    center.x += vPerp.x;
    center.y += vPerp.y;
    
    return center;
}

- (void)centerAtPositionForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer inView:(UIView *)view;
{
    // If no gesture recognizer was specified, fall back to aligning mid-center
    if (!gestureRecognizer) {
        [self useAlignment:OUIOverlayViewAlignmentMidCenter withinBounds:view.bounds];
        return;
    }
    
    // If gesture recognizer has just one touch, fall back to positioning above the finger
    if ([gestureRecognizer numberOfTouches] == 1) {
        [self centerAbovePoint:[gestureRecognizer locationInView:view] withinBounds:view.bounds];
        return;
    }
    
    CGPoint p = [self positionForTwoTouchGestureRecognizer:gestureRecognizer inView:view];
    
    [self centerAtPoint:p withOffset:CGPointZero withinBounds:view.bounds];
}

#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect;
{
    CGRect bounds = self.bounds;
        
    [[isa backgroundImage] drawInRect:bounds blendMode:kCGBlendModeNormal alpha:0.8];
    
    // Draw text
    if (self.text.length) {
        [[UIColor whiteColor] set];
        CGRect textRect = CGRectInset(bounds, self.borderSize.width, self.borderSize.height);
        [self.text drawInRect:textRect withFont:_font];
    }
}

@end
