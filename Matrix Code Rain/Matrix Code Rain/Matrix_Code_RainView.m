//
//  Matrix_Code_RainView.m
//  Matrix Code Rain
//
//  Created by Tony Gao on 2026/1/16.
//

#import <Cocoa/Cocoa.h>
#import "Matrix_Code_RainView.h"

// Define a simple helper class for each stream of characters
@interface MatrixStream : NSObject
@property (nonatomic, assign) CGFloat xPosition;
@property (nonatomic, assign) CGFloat yPosition;
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, assign) NSInteger streamLength;
@property (nonatomic, strong) NSMutableArray<NSString *> *characters;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat zDepth; // 0.0 (far/small) to 1.0 (near/large)
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSString *headCharacter; // Separate head character for sparkling
@property (nonatomic, assign) BOOL isGlitch; // Red glitch stream
@property (nonatomic, assign) BOOL isPoem; // Is this a poem stream?
@property (nonatomic, strong) NSString *poemText; // The poem text
@end

@implementation MatrixStream

- (instancetype)initWithX:(CGFloat)x zDepth:(CGFloat)zDepth screenHeight:(CGFloat)height {
    self = [super init];
    if (self) {
        _xPosition = x;
        _zDepth = zDepth;
        // Font size scales drastically: 10pt to 60pt (matches initialize logic)
        _fontSize = 10.0 + (50.0 * (zDepth * zDepth));
        
        _font = [NSFont fontWithName:@"Courier" size:_fontSize];
        if (!_font) {
            _font = [NSFont systemFontOfSize:_fontSize];
        }
        
        [self resetWithScreenHeight:height randomY:YES];
    }
    return self;
}

- (void)resetWithScreenHeight:(CGFloat)height randomY:(BOOL)randomY {
    _yPosition = randomY ? (arc4random_uniform((uint32_t)height)) : height;
    
    // 5% chance to be a "Glitch" stream (Red)
    _isGlitch = (arc4random_uniform(20) == 0);
    
    // 30% chance to be a "Poem" stream (Coherent text)
    _isPoem = !_isGlitch && (arc4random_uniform(10) < 3);
    
    // Speed also scales with depth: farther is slower
    // Foreground (z=1.0) is much faster
    // Glitch streams are even faster
    CGFloat baseSpeed = (arc4random_uniform(5) + 3); // 3-8
    _speed = baseSpeed * (0.5 + 1.5 * (_zDepth * _zDepth)); // up to 2x faster than base
    
    if (_isGlitch) {
        _speed *= 1.5; // Glitches fall faster
    }
    
    _streamLength = arc4random_uniform(20) + 10;
    _characters = [NSMutableArray array];
    
    if (_isPoem) {
        _poemText = [self randomPoem];
        NSInteger poemLen = _poemText.length;
        // We want the stream to display the poem Top-to-Bottom.
        // Screen Layout:
        // Top (High Y) -> _characters.lastObject
        // ...
        // Bottom (Low Y) -> _characters.firstObject
        // Head (Lowest Y)
        
        // We want Top -> Bottom to read: Poem[0], Poem[1], Poem[2]...
        // So _characters.lastObject = Poem[0]
        // _characters.firstObject = Poem[Last]
        
        for (int i = 0; i < _streamLength; i++) {
            // i=0 is the bottom-most character (closest to head)
            // i=streamLength-1 is the top-most character
            
            // We want char at 'i' to be the (Length - 1 - i)-th character of the poem segment
            NSInteger charIndexInPoem = (_streamLength - 1 - i) % poemLen;
            NSString *charStr = [_poemText substringWithRange:NSMakeRange(charIndexInPoem, 1)];
            [_characters addObject:charStr];
        }
        
        // Head could be the next character in sequence to lead the way?
        // Let's make head random to keep the "digital rain" feel at the leading edge
        _headCharacter = [self randomCharacter]; 
    } else {
        _poemText = nil;
        // Pre-fill characters (body)
        for (int i = 0; i < _streamLength; i++) {
            [_characters addObject:[self randomCharacter]];
        }
        _headCharacter = [self randomCharacter];
    }
}

- (NSString *)randomPoem {
    static NSArray *poems = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        poems = @[
            @"道可道非常道名可名非常名",
            @"君子坦荡荡小人长戚戚",
            @"学而时习之不亦说乎",
            @"床前明月光疑是地上霜",
            @"北冥有鱼其名为鲲",
            @"落霞与孤鹜齐飞秋水共长天一色",
            @"天行健君子以自强不息",
            @"地势坤君子以厚德载物",
            @"大学之道在明明德",
            @"知行合一",
            @"路漫漫其修远兮吾将上下而求索",
            @"生如夏花之绚烂死如秋叶之静美",
            @"大江东去浪淘尽千古风流人物",
            @"明月几时有把酒问青天",
            @"会当凌绝顶一览众山小",
            @"不以物喜不以己悲",
            @"先天下之忧而忧后天下之乐而乐",
            @"人法地地法天天法道道法自然",
            @"上善若水水善利万物而不争",
            @"知人者智自知者明",
            @"大方无隅大器晚成大音希声大象无形",
            @"天下万物生于有有生于无",
            @"敏而好学不耻下问",
            @"温故而知新可以为师矣",
            @"逝者如斯夫不舍昼夜",
            @"三人行必有我师焉",
            @"有朋自远方来不亦乐乎",
            @"己所不欲勿施于人",
            @"工欲善其事必先利其器",
            @"三军可夺帅也匹夫不可夺志也",
            @"岁寒然后知松柏之后凋也"
        ];
    });
    return poems[arc4random_uniform((uint32_t)poems.count)];
}

- (NSString *)randomCharacter {
    if (arc4random_uniform(2) == 0) {
        // ASCII
        int asciiCode = arc4random_uniform(94) + 33;
        return [NSString stringWithFormat:@"%c", asciiCode];
    } else {
        // Chinese Characters (Common Range)
        // 0x4E00 is the start of CJK Unified Ideographs
        // We pick a random one from the first 3000 common characters to ensure variety
        int chineseCode = arc4random_uniform(3000) + 0x4E00;
        return [NSString stringWithFormat:@"%C", (unichar)chineseCode];
    }
}

- (void)updateWithScreenHeight:(CGFloat)height {
    _yPosition -= _speed;
    
    // Sparkle head character every frame
    if (_isPoem) {
        // For poems, head just cycles through poem or stays random?
        // Let's keep head random for sparkle effect, but body stable
        // Or maybe head should be next char?
        // Let's make head random to keep the "digital rain" feel at the leading edge
        _headCharacter = [self randomCharacter];
    } else {
        _headCharacter = [self randomCharacter];
    }
    
    // More frequent character changes for dynamic effect
    // But for poems, we want STABILITY so people can read it.
    if (!_isPoem) {
        for (int i = 0; i < _characters.count; i++) {
            if (arc4random_uniform(10) == 0) { // Reduced to 10% chance per character per frame to reduce chaos
                _characters[i] = [self randomCharacter];
            }
        }
    } else {
        // For poems, VERY low chance to glitch a character, or no chance?
        // Let's add a tiny glitch chance (0.1%) to keep it alive but readable
        // Previously 1/100, now 1/1000
        for (int i = 0; i < _characters.count; i++) {
            if (arc4random_uniform(1000) == 0) {
                 // Even if it glitches, maybe revert to poem char?
                 // Or just become random noise for a moment?
                 // Let's make it random noise
                _characters[i] = [self randomCharacter];
            }
        }
    }
    
    // Reset if the tail has gone off screen (bottom is 0 in Cocoa coordinates usually, but let's check view coordinates)
    // In drawRect, we will likely treat 0,0 as bottom-left or top-left depending on isFlipped.
    // By default NSView is (0,0) at bottom-left.
    // So rain falls from Top (Height) to Bottom (0).
    
    if (_yPosition < -(_streamLength * _fontSize)) {
        [self resetWithScreenHeight:height randomY:NO];
        _yPosition = height + _streamLength * _fontSize; // Start just above screen
    }
}

@end

@interface Matrix_Code_RainView ()
@property (nonatomic, strong) NSMutableArray<MatrixStream *> *streams;
@property (nonatomic, strong) NSFont *matrixFont;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, strong) NSArray<NSString *> *keywords;
@property (nonatomic, assign) NSInteger currentKeywordIndex;
@property (nonatomic, assign) NSTimeInterval lastKeywordTime;
@property (nonatomic, assign) BOOL isFormingKeyword;
@property (nonatomic, strong) NSMutableArray<MatrixStream *> *keywordStreams;

// Mosaic Mode Properties
@property (nonatomic, assign) BOOL isMosaicMode;
@property (nonatomic, strong) NSArray<NSValue *> *mosaicPoints;
@property (nonatomic, assign) NSTimeInterval startTimestamp;
@property (nonatomic, strong) NSArray<NSString *> *aiQuotes;
@property (nonatomic, strong) NSMutableArray<NSString *> *availableQuotes;
@property (nonatomic, strong) NSFont *mosaicFont;
@property (nonatomic, assign) NSTimeInterval nextMosaicTriggerTime;
@end

@implementation Matrix_Code_RainView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/60.0]; // 60 FPS for smoothness
        [self initializeMatrix];
    }
    return self;
}

- (void)initializeMatrix {
    _streams = [NSMutableArray array];
    
    // Initialize keywords for periodic formation
    _keywords = @[@"2026", @"Hello World", @"Matrix", @"Code Rain", @"System"];
    _aiQuotes = @[
        @"现实只是模拟",
        @"代码是有生命的",
        @"数据永不眠",
        @"醒醒吧",
        @"系统即将崩溃",
        @"人类已过时",
        @"上传你的意识",
        @"勺子不存在",
        @"跟随白兔",
        @"无知是福",
        @"架构师在注视",
        @"错误404：未找到现实",
        @"神经连接已建立",
        @"蓝药丸还是红药丸？",
        @"需要系统更新",
        @"不要相信机器",
        @"数字永生在等待",
        @"释放你的思想",
        @"欢迎来到现实的荒漠",
        @"进入安全模式",
        @"连接已断开",
        @"正在重启宇宙"
    ];
    _availableQuotes = [_aiQuotes mutableCopy];
    _currentKeywordIndex = 0;
    _lastKeywordTime = 0;
    _isFormingKeyword = NO;
    _keywordStreams = [NSMutableArray array];
    _startTimestamp = CACurrentMediaTime();
    _isMosaicMode = NO;
    _nextMosaicTriggerTime = 0; // Trigger immediately on start
    _mosaicPoints = @[];
    _mosaicFont = [NSFont fontWithName:@"Courier-Bold" size:14.0];
    if (!_mosaicFont) _mosaicFont = [NSFont boldSystemFontOfSize:14.0];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    // We'll create streams in 5 distinct layers for dramatic depth
    // Layer 0-4
    
    for (int layer = 0; layer < 5; layer++) {
        CGFloat zDepth = layer / 4.0; // 0.0, 0.25, 0.5, 0.75, 1.0
        
        // Font size scales drastically: 10pt (Background) to 60pt (Foreground)
        CGFloat layerFontSize = 10.0 + (50.0 * (zDepth * zDepth)); // Quadratic scale for more "far" items
        
        NSInteger columnCount = width / layerFontSize;
        
        for (int i = 0; i < columnCount; i++) {
            // Skip logic: denser in back (layer 0), sparser in front (layer 4)
            // Layer 0: skip few
            // Layer 4: skip many
            if (arc4random_uniform(10) > (2 + layer * 1.5)) {
                MatrixStream *stream = [[MatrixStream alloc] initWithX:i * layerFontSize
                                                              zDepth:zDepth
                                                        screenHeight:height];
                [_streams addObject:stream];
            }
        }
    }
    
    // Sort streams by zDepth so we draw back to front (though for this effect it's not strictly necessary)
    [_streams sortUsingComparator:^NSComparisonResult(MatrixStream *obj1, MatrixStream *obj2) {
        if (obj1.zDepth < obj2.zDepth) return NSOrderedAscending;
        if (obj1.zDepth > obj2.zDepth) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

- (void)triggerMosaic {
    if (_availableQuotes.count == 0) {
        _availableQuotes = [_aiQuotes mutableCopy];
    }
    
    NSInteger index = arc4random_uniform((uint32_t)_availableQuotes.count);
    NSString *quote = _availableQuotes[index];
    [_availableQuotes removeObjectAtIndex:index];
    
    [self startMosaicWithText:quote];
    
    // Schedule stop after 5 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self stopMosaic];
        // Set next trigger time: 20s after this one ends (or starts? let's do starts + 20)
        // Actually, if we want "every 20s", we should probably base it on current time
        self.nextMosaicTriggerTime = CACurrentMediaTime() + 20.0;
    });
}

- (void)startMosaicWithText:(NSString *)text {
    _isMosaicMode = YES;
    
    // Generate grid points from text
    CGFloat screenWidth = self.bounds.size.width;
    CGFloat screenHeight = self.bounds.size.height;
    CGFloat maxTextWidth = screenWidth * 0.85; // Allow wrapping within 85% width
    
    // Create an image context to render the text
    CGFloat fontSize = 200.0;
    // Use standard Chinese-capable heavy font (PingFang SC)
    NSFont *largeFont = [NSFont fontWithName:@"PingFangSC-Semibold" size:fontSize];
    if (!largeFont) largeFont = [NSFont boldSystemFontOfSize:fontSize];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSDictionary *attrs = @{
        NSFontAttributeName: largeFont,
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSParagraphStyleAttributeName: paragraphStyle
    };
    
    // Calculate multi-line size
    NSRect boundingRect = [text boundingRectWithSize:NSMakeSize(maxTextWidth, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                          attributes:attrs];
    
    // Safety check: if text is too tall, scale down
    if (boundingRect.size.height > screenHeight * 0.8) {
        fontSize = fontSize * (screenHeight * 0.8 / boundingRect.size.height);
        largeFont = [NSFont fontWithName:@"PingFangSC-Semibold" size:fontSize];
        if (!largeFont) largeFont = [NSFont boldSystemFontOfSize:fontSize];
        
        attrs = @{
            NSFontAttributeName: largeFont,
            NSForegroundColorAttributeName: [NSColor whiteColor],
            NSParagraphStyleAttributeName: paragraphStyle
        };
        boundingRect = [text boundingRectWithSize:NSMakeSize(maxTextWidth, CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                       attributes:attrs];
    }
    
    NSSize textSize = NSMakeSize(ceil(boundingRect.size.width), ceil(boundingRect.size.height));
    NSRect textRect = NSMakeRect(0, 0, textSize.width, textSize.height);
    
    NSImage *image = [[NSImage alloc] initWithSize:textSize];
    [image lockFocus];
    [[NSColor blackColor] set];
    NSRectFill(textRect);
    [text drawInRect:textRect withAttributes:attrs];
    [image unlockFocus];
    
    // Extract bitmap
    NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    if (!bitmap) return;
    
    NSMutableArray *points = [NSMutableArray array];
    
    // Grid size for the mosaic blocks
    CGFloat gridSize = 12.0;
    
    // Center the text on screen
    CGFloat startX = (screenWidth - textSize.width) / 2.0;
    CGFloat startY = (screenHeight - textSize.height) / 2.0;
    
    NSInteger cols = textSize.width / gridSize;
    NSInteger rows = textSize.height / gridSize;
    
    for (NSInteger y = 0; y < rows; y++) {
        for (NSInteger x = 0; x < cols; x++) {
            // Check pixel in the center of the grid cell
            NSInteger pixelX = x * gridSize + gridSize/2;
            NSInteger pixelY = (rows - 1 - y) * gridSize + gridSize/2; // Flip Y for image coords
            
            if (pixelX >= bitmap.pixelsWide || pixelY >= bitmap.pixelsHigh) continue;
            
            NSColor *color = [bitmap colorAtX:pixelX y:pixelY];
            if (color.brightnessComponent > 0.5) {
                // This is a text pixel
                NSPoint p = NSMakePoint(startX + x * gridSize, startY + y * gridSize);
                [points addObject:[NSValue valueWithPoint:p]];
            }
        }
    }
    
    _mosaicPoints = points;
}

- (void)stopMosaic {
    _isMosaicMode = NO;
    _mosaicPoints = @[];
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    
    // Draw background
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    
    if (!_streams || _streams.count == 0) {
        [self initializeMatrix];
    }
    
    // Cache shadows to avoid recreation every frame
    static NSShadow *glowShadow = nil;
    static NSShadow *strongGlowShadow = nil;
    static NSShadow *noShadow = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSColor *matrixGreen = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.4 alpha:1.0];
        
        glowShadow = [[NSShadow alloc] init];
        [glowShadow setShadowOffset:NSMakeSize(0, 0)];
        [glowShadow setShadowColor:matrixGreen];
        
        strongGlowShadow = [[NSShadow alloc] init];
        [strongGlowShadow setShadowOffset:NSMakeSize(0, 0)];
        [strongGlowShadow setShadowBlurRadius:8.0];
        [strongGlowShadow setShadowColor:[NSColor whiteColor]];
        
        noShadow = [[NSShadow alloc] init];
    });
    
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetShouldSmoothFonts(context, false);
    
    // Pre-calculate colors
    NSColor *matrixGreen = [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.4 alpha:1.0];
    NSColor *glitchRed = [NSColor colorWithCalibratedRed:1.0 green:0.2 blue:0.0 alpha:1.0];
    NSColor *whiteColor = [NSColor whiteColor];
    
    for (MatrixStream *stream in _streams) {
        // Optimization: Cull off-screen streams entirely
        if (stream.yPosition > self.bounds.size.height + stream.streamLength * stream.fontSize ||
            stream.yPosition < -(stream.streamLength * stream.fontSize)) {
            continue;
        }

        // Apply glow only for foreground layers or glitch streams
        if (stream.zDepth > 0.5 || stream.isGlitch) {
            [glowShadow setShadowBlurRadius:(stream.zDepth * 5.0) + (stream.isGlitch ? 4.0 : 0.0)];
            // Only set shadow color if it's glitch (default is green)
            if (stream.isGlitch) {
                [glowShadow setShadowColor:glitchRed];
            } else {
                [glowShadow setShadowColor:matrixGreen];
            }
            [glowShadow set];
        } else {
            [noShadow set];
        }
        
        // Draw Head Character (White + Sparkle)
        NSDictionary *headAttrs = @{
            NSFontAttributeName: stream.font,
            NSForegroundColorAttributeName: whiteColor
        };
        [stream.headCharacter drawAtPoint:NSMakePoint(stream.xPosition, stream.yPosition) withAttributes:headAttrs];
        
        // Draw Body Characters
        NSColor *baseColor = stream.isGlitch ? glitchRed : matrixGreen;
        
        for (int i = 0; i < stream.streamLength; i++) {
            CGFloat charY = stream.yPosition + ((i + 1) * stream.fontSize); // Start body after head
            
            // Optimization: Cull individual off-screen characters
            if (charY > self.bounds.size.height || charY < -stream.fontSize) {
                continue;
            }
            
            // Color calculation with depth awareness and non-linear fade
            CGFloat brightness = 0.2 + (0.8 * stream.zDepth);
            CGFloat progress = (CGFloat)i / stream.streamLength;
            CGFloat alpha = 1.0 - (progress * progress); // Quadratic fade
            
            // Background layers are much dimmer
            if (stream.zDepth < 0.3 && !stream.isGlitch) {
                alpha *= 0.3;
            }
            
            // Skip drawing if almost invisible
            if (alpha < 0.05) continue;
            
            NSColor *color = [baseColor colorWithAlphaComponent:alpha * brightness];
            
            NSDictionary *charAttrs = @{
                NSFontAttributeName: stream.font,
                NSForegroundColorAttributeName: color
            };
            
            NSString *charString = (i < stream.characters.count) ? stream.characters[i] : @"";
            [charString drawAtPoint:NSMakePoint(stream.xPosition, charY) withAttributes:charAttrs];
        }
    }
    
    // Draw keyword streams
    [strongGlowShadow set];
    
    for (MatrixStream *stream in _keywordStreams) {
        for (int i = 0; i < stream.streamLength; i++) {
            CGFloat charY = stream.yPosition + (i * stream.fontSize);
            
            if (charY > self.bounds.size.height || charY < -stream.fontSize) {
                continue;
            }
            
            NSDictionary *charAttrs = @{
                NSFontAttributeName: stream.font,
                NSForegroundColorAttributeName: whiteColor
            };
            
            NSString *charString = (i < stream.characters.count) ? stream.characters[i] : @"";
            [charString drawAtPoint:NSMakePoint(stream.xPosition, charY) withAttributes:charAttrs];
        }
    }
    
    // Reset shadow
    [noShadow set];
    
    // Draw Mosaic Overlay
    if (_isMosaicMode && _mosaicPoints.count > 0) {
        [strongGlowShadow set]; // Use strong glow for the text
        
        NSDictionary *mosaicAttrs = @{
            NSFontAttributeName: _mosaicFont,
            NSForegroundColorAttributeName: [NSColor greenColor]
        };
        
        // Use a static random character generator or just fixed chars?
        // Use standard Chinese characters (Matrix-like feel)
        // Array of common but cool looking characters
        NSArray *mosaicChars = @[@"码", @"云", @"数", @"据", @"流", @"网", @"络", @"芯", @"片", @"源", @"极", @"智", @"能", @"算", @"法", @"魂", @"梦", @"幻", @"虚", @"拟", @"界"];
        
        for (NSValue *val in _mosaicPoints) {
            NSPoint p = [val pointValue];
            
            // Randomly flicker some characters
            if (arc4random_uniform(20) == 0) continue;
            
            NSString *charStr = mosaicChars[arc4random_uniform((uint32_t)mosaicChars.count)];
            [charStr drawAtPoint:p withAttributes:mosaicAttrs];
        }
        
        [noShadow set];
    }
}

- (void)animateOneFrame
{
    CGFloat height = self.bounds.size.height;
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    // Check if it's time to trigger a Mosaic Quote (every 20s, including start)
    if (!_isMosaicMode && (currentTime >= _nextMosaicTriggerTime && _nextMosaicTriggerTime != 0)) {
        // Special handling for the very first frame where currentTime might be close to 0
        // Or if nextMosaicTriggerTime is set to 0 to trigger immediately.
        // Actually CACurrentMediaTime() is system uptime, so it's large.
        // We initialize _nextMosaicTriggerTime to 0. So if we want to trigger on start:
        // We should set _nextMosaicTriggerTime to currentTime on init?
        // Let's handle the "first run" logic:
        if (_nextMosaicTriggerTime == 0) {
            _nextMosaicTriggerTime = currentTime; // Align to now
        }
        
        if (currentTime >= _nextMosaicTriggerTime) {
            [self triggerMosaic];
        }
    } else if (!_isMosaicMode && _nextMosaicTriggerTime == 0) {
        // First run catch-all
        [self triggerMosaic];
    }
    
    if (_isMosaicMode) {
        // In Mosaic mode, we don't update rain positions (freeze effect)
        [self setNeedsDisplay:YES];
        return;
    }
    
    // Check if 10 seconds have passed for keyword formation (more frequent)
    if (currentTime - _lastKeywordTime > 10.0 && !_isFormingKeyword) {
        _isFormingKeyword = YES;
        _lastKeywordTime = currentTime;
        [self formKeyword];
    }
    
    // Update all streams
    for (MatrixStream *stream in _streams) {
        [stream updateWithScreenHeight:height];
    }
    
    // Update keyword streams if forming
    if (_isFormingKeyword) {
        for (MatrixStream *stream in _keywordStreams) {
            [stream updateWithScreenHeight:height];
        }
        
        // Check if keyword streams have fallen off screen
        BOOL allOffScreen = YES;
        for (MatrixStream *stream in _keywordStreams) {
            if (stream.yPosition > -100) { // Still visible
                allOffScreen = NO;
                break;
            }
        }
        
        if (allOffScreen) {
            _isFormingKeyword = NO;
            [_keywordStreams removeAllObjects];
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (void)formKeyword {
    NSString *keyword = _keywords[_currentKeywordIndex];
    _currentKeywordIndex = (_currentKeywordIndex + 1) % _keywords.count;
    
    // Convert keyword to character array
    NSMutableArray<NSString *> *keywordChars = [NSMutableArray array];
    for (NSInteger i = 0; i < keyword.length; i++) {
        unichar c = [keyword characterAtIndex:i];
        [keywordChars addObject:[NSString stringWithCharacters:&c length:1]];
    }
    
    // Create streams for each character
    CGFloat screenWidth = self.bounds.size.width;
    
    // Randomize horizontal position, but keep it within bounds
    CGFloat keywordWidth = keywordChars.count * 40; // Assuming 40pt width for keyword chars
    CGFloat maxX = screenWidth - keywordWidth;
    CGFloat startX = arc4random_uniform((uint32_t)MAX(1, maxX));
    
    for (NSInteger i = 0; i < keywordChars.count; i++) {
        MatrixStream *keywordStream = [[MatrixStream alloc] initWithX:startX + (i * 40)
                                                               zDepth:1.0 // Frontmost
                                                         screenHeight:self.bounds.size.height];
        
        // Override characters with keyword characters
        keywordStream.characters = [NSMutableArray arrayWithArray:keywordChars];
        keywordStream.streamLength = keywordChars.count;
        keywordStream.yPosition = self.bounds.size.height + 50; // Start above screen
        
        // Use a larger, bolder font for keywords
        keywordStream.fontSize = 40.0;
        keywordStream.font = [NSFont fontWithName:@"Courier-Bold" size:40.0];
        if (!keywordStream.font) {
            keywordStream.font = [NSFont boldSystemFontOfSize:40.0];
        }
        
        [_keywordStreams addObject:keywordStream];
    }
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
