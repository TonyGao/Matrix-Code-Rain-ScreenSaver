//
//  Matrix_Code_RainView.m
//  Matrix Code Rain
//
//  Created by Tony Gao on 2026/1/16.
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <mach/mach.h>
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
@property (nonatomic, assign) NSTimeInterval lastHeadUpdateTime;
@property (nonatomic, assign) NSTimeInterval lastBodyUpdateTime;
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
    
    // 80% chance to be a "Poem" stream (Coherent text) - Increased from 30%
    _isPoem = !_isGlitch && (arc4random_uniform(10) < 8);
    
    // Speed also scales with depth: farther is slower
    // Foreground (z=1.0) is much faster
    // Glitch streams are even faster
    // Reduced speed for readability: (2..6) * 15.0 = 30..90 (Previously 180-480)
    CGFloat baseSpeed = (arc4random_uniform(5) + 2) * 15.0; 
    _speed = baseSpeed * (0.5 + 1.5 * (_zDepth * _zDepth)); // up to 2x faster than base
    
    if (_isGlitch) {
        _speed *= 1.5; // Glitches fall faster
    }
    
    _streamLength = arc4random_uniform(20) + 10;
    _characters = [NSMutableArray array];
    _lastHeadUpdateTime = 0;
    _lastBodyUpdateTime = 0;
    
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
            @"岁寒然后知松柏之后凋也",
            @"朝闻道夕死可矣",
            @"知之者不如好之者好之者不如乐之者",
            @"士不可以不弘毅任重而道远",
            @"见贤思齐焉见不贤而内自省也",
            @"德不孤必有邻",
            @"礼之用和为贵",
            @"言必信行必果",
            @"君子和而不同小人同而不和",
            @"吾日三省吾身",
            @"学而不思则罔思而不学则殆",
            @"人无远虑必有近忧",
            @"君子成人之美不成人之恶",
            @"和而不同周而不比",
            @"知者不惑仁者不忧勇者不惧",
            @"志士仁人无求生以害仁有杀身以成仁",
            @"博学而笃志切问而近思",
            @"欲速则不达见小利则大事不成",
            @"君子喻于义小人喻于利",
            @"苟日新日日新又日新",
            @"天将降大任于斯人也必先苦其心志",
            @"生于忧患死于安乐",
            @"得道者多助失道者寡助",
            @"富贵不能淫贫贱不能移威武不能屈",
            @"老吾老以及人之老幼吾幼以及人之幼",
            @"穷则独善其身达则兼济天下",
            @"民为贵社稷次之君为轻",
            @"锲而舍之朽木不折锲而不舍金石可镂",
            @"青取之于蓝而青于蓝",
            @"不积跬步无以至千里",
            @"海纳百川有容乃大",
            @"壁立千仞无欲则刚",
            @"业精于勤荒于嬉行成于思毁于随",
            @"纸上得来终觉浅绝知此事要躬行",
            @"春蚕到死丝方尽蜡炬成灰泪始干",
            @"身无彩凤双飞翼心有灵犀一点通",
            @"曾经沧海难为水除却巫山不是云",
            @"无可奈何花落去似曾相识燕归来",
            @"山重水复疑无路柳暗花明又一村",
            @"不识庐山真面目只缘身在此山中",
            @"欲穷千里目更上一层楼",
            @"人生自古谁无死留取丹心照汗青",
            @"三十功名尘与土八千里路云和月",
            @"莫等闲白了少年头空悲切",
            @"众里寻他千百度蓦然回首那人却在灯火阑珊处",
            @"衣带渐宽终不悔为伊消得人憔悴",
            @"两情若是久长时又岂在朝朝暮暮",
            @"大漠孤烟直长河落日圆",
            @"星垂平野阔月涌大江流",
            @"无边落木萧萧下不尽长江滚滚来",
            @"露从今夜白月是故乡明",
            @"海内存知己天涯若比邻",
            @"海上生明月天涯共此时",
            @"举头望明月低头思故乡",
            @"野火烧不尽春风吹又生",
            @"谁言寸草心报得三春晖",
            @"读书破万卷下笔如有神",
            @"长风破浪会有时直挂云帆济沧海",
            @"天生我材必有用千金散尽还复来",
            @"安能摧眉折腰事权贵使我不得开心颜",
            @"抽刀断水水更流举杯消愁愁更愁",
            @"两岸猿声啼不住轻舟已过万重山",
            @"采菊东篱下悠然见南山",
            @"羁鸟恋旧林池鱼思故渊",
            @"久在樊笼里复得返自然",
            @"少壮不努力老大徒伤悲",
            @"明日复明日明日何其多",
            @"一寸光阴一寸金寸金难买寸光阴",
            @"近朱者赤近墨者黑",
            @"前事不忘后事之师",
            @"千里之行始于足下",
            @"信言不美美言不信",
            @"善者不辩辩者不善",
            @"知者不博博者不知",
            @"圣人无常心以百姓心为心",
            @"祸兮福之所倚福兮祸之所伏",
            @"合抱之木生于毫末",
            @"九层之台起于累土",
            @"慎终如始则无败事",
            @"治大国若烹小鲜"
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

- (void)updateWithScreenHeight:(CGFloat)height
                     deltaTime:(NSTimeInterval)deltaTime
                   currentTime:(NSTimeInterval)currentTime
              headUpdateEvery:(NSTimeInterval)headUpdateInterval
              bodyUpdateEvery:(NSTimeInterval)bodyUpdateInterval
          bodyChangeDenominator:(uint32_t)bodyChangeDenominator
{
    if (deltaTime <= 0) deltaTime = 0;
    _yPosition -= _speed * (CGFloat)deltaTime;
    
    if (headUpdateInterval > 0 && (currentTime - _lastHeadUpdateTime) >= headUpdateInterval) {
        _headCharacter = [self randomCharacter];
        _lastHeadUpdateTime = currentTime;
    }
    
    if (bodyUpdateInterval > 0 && (currentTime - _lastBodyUpdateTime) >= bodyUpdateInterval) {
        if (!_isPoem) {
            uint32_t denom = bodyChangeDenominator == 0 ? 1 : bodyChangeDenominator;
            for (int i = 0; i < _characters.count; i++) {
                if (arc4random_uniform(denom) == 0) {
                    _characters[i] = [self randomCharacter];
                }
            }
        } else {
            for (int i = 0; i < _characters.count; i++) {
                if (arc4random_uniform(2000) == 0) {
                    _characters[i] = [self randomCharacter];
                }
            }
        }
        _lastBodyUpdateTime = currentTime;
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
@property (nonatomic, assign) NSTimeInterval mosaicEndTime;
@property (nonatomic, assign) NSTimeInterval mosaicInterval;
@property (nonatomic, assign) NSTimeInterval mosaicDuration;
@property (nonatomic, assign) NSTimeInterval keywordInterval;
@property (nonatomic, assign) BOOL mosaicEnabled;
@property (nonatomic, assign) BOOL isWallpaperHost;
@property (nonatomic, assign) BOOL isPreviewHost;
@property (nonatomic, assign) BOOL isAnimatingActive;
@property (nonatomic, assign) NSTimeInterval lastFrameTimestamp;
@property (nonatomic, assign) BOOL didRegisterSystemEventObservers;
@property (nonatomic, assign) BOOL systemScreenSaverIsActive;
@property (nonatomic, assign) NSTimeInterval activeAnimationInterval;
@property (nonatomic, assign) NSTimeInterval idleAnimationInterval;
@property (nonatomic, assign) NSInteger qualityLevel;
@property (nonatomic, assign) NSInteger qualityLayerCount;
@property (nonatomic, assign) uint32_t qualityDensityPercent;
@property (nonatomic, assign) BOOL qualityAllowGlow;
@property (nonatomic, assign) BOOL qualityMosaicEnabled;
@property (nonatomic, assign) NSTimeInterval qualityHeadUpdateInterval;
@property (nonatomic, assign) NSTimeInterval qualityBodyUpdateInterval;
@property (nonatomic, assign) uint32_t qualityBodyChangeDenominator;
@property (nonatomic, assign) NSTimeInterval lastCPUSampleTime;
@property (nonatomic, assign) NSTimeInterval lastQualityChangeTime;
@property (nonatomic, assign) float targetCPUPercent;
@property (nonatomic, assign) BOOL didHandleStopForCurrentSession;
@property (nonatomic, assign) BOOL didScheduleStopAfterAlert;

- (void)systemScreenSaverDidStart:(NSNotification *)notification;
- (void)systemScreenSaverDidStop:(NSNotification *)notification;
- (void)triggerMosaicWithDuration:(NSTimeInterval)duration;
@end

static NSHashTable<Matrix_Code_RainView *> *gLegacyHostViews = nil;
static id gLegacyHostDidStartObserver = nil;
static id gLegacyHostDidStopObserver = nil;

static NSHashTable<Matrix_Code_RainView *> *LegacyHostViews(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gLegacyHostViews = [NSHashTable weakObjectsHashTable];
    });
    return gLegacyHostViews;
}

static void InstallLegacyHostSystemEventObserversIfNeeded(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        
        gLegacyHostDidStartObserver = [center addObserverForName:@"com.apple.screensaver.didstart"
                                                         object:nil
                                                          queue:queue
                                                     usingBlock:^(NSNotification * _Nonnull note) {
            for (Matrix_Code_RainView *view in LegacyHostViews().allObjects) {
                [view systemScreenSaverDidStart:note];
            }
        }];
        
        gLegacyHostDidStopObserver = [center addObserverForName:@"com.apple.screensaver.didstop"
                                                        object:nil
                                                         queue:queue
                                                    usingBlock:^(NSNotification * _Nonnull note) {
            for (Matrix_Code_RainView *view in LegacyHostViews().allObjects) {
                [view systemScreenSaverDidStop:note];
            }
        }];
    });
}

@implementation Matrix_Code_RainView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        NSString *processName = [NSProcessInfo processInfo].processName ?: @"";
        _isWallpaperHost = [[processName lowercaseString] isEqualToString:@"legacyscreensaver"];
        _isPreviewHost = isPreview;
        
        _activeAnimationInterval = 1.0 / 60.0;
        _idleAnimationInterval = 1.0;
        _systemScreenSaverIsActive = !_isWallpaperHost;
        _lastCPUSampleTime = 0;
        _lastQualityChangeTime = 0;
        _targetCPUPercent = _isPreviewHost ? 12.0f : 25.0f;
        
        _qualityLevel = 3;
        
        _mosaicEnabled = !_isPreviewHost;
        _mosaicInterval = 45.0;
        _mosaicDuration = 4.0;
        _keywordInterval = _isWallpaperHost ? 45.0 : 12.0;
        
        [self applyQualityLevel:_qualityLevel];
        [self initializeMatrix];
    }
    return self;
}

- (void)dealloc
{
    [self unregisterSystemEventObservers];
}

- (void)registerSystemEventObserversIfNeeded
{
    if (_didRegisterSystemEventObservers) return;
    if (!_isWallpaperHost) return;
    if (_isPreviewHost) return;
    
    InstallLegacyHostSystemEventObserversIfNeeded();
    [LegacyHostViews() addObject:self];
    _didRegisterSystemEventObservers = YES;
}

- (void)unregisterSystemEventObservers
{
    if (!_didRegisterSystemEventObservers) return;
    [LegacyHostViews() removeObject:self];
    _didRegisterSystemEventObservers = NO;
}

- (float)currentProcessCPUUsagePercent
{
    thread_act_array_t threads = NULL;
    mach_msg_type_number_t threadCount = 0;
    kern_return_t kr = task_threads(mach_task_self(), &threads, &threadCount);
    if (kr != KERN_SUCCESS || threads == NULL) return -1.0f;
    
    float totalCPU = 0.0f;
    for (mach_msg_type_number_t i = 0; i < threadCount; i++) {
        thread_basic_info_data_t info;
        mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
        if (thread_info(threads[i], THREAD_BASIC_INFO, (thread_info_t)&info, &count) != KERN_SUCCESS) continue;
        if (info.flags & TH_FLAGS_IDLE) continue;
        totalCPU += ((float)info.cpu_usage / (float)TH_USAGE_SCALE) * 100.0f;
    }
    
    vm_deallocate(mach_task_self(), (vm_address_t)threads, threadCount * sizeof(thread_t));
    return totalCPU;
}

- (void)applyQualityLevel:(NSInteger)level
{
    NSInteger clamped = level;
    if (clamped < 0) clamped = 0;
    if (clamped > 3) clamped = 3;
    
    NSInteger previousLayerCount = _qualityLayerCount;
    uint32_t previousDensity = _qualityDensityPercent;
    NSInteger previousLevel = _qualityLevel;
    
    _qualityLevel = clamped;
    
    // We LOCK the geometry (layer count/density) to the highest level
    // to prevent matrix rebuilding which causes "flashing/reset" effects.
    // Quality adjustment will ONLY affect framerate and update frequency.
    
    // Always use max geometry settings regardless of level
    _qualityLayerCount = 5;
    _qualityDensityPercent = 60;
    
    if (_qualityLevel == 3) {
        _activeAnimationInterval = 1.0 / 60.0;
        _qualityAllowGlow = YES;
        _qualityMosaicEnabled = YES;
        _qualityHeadUpdateInterval = 0.08;
        _qualityBodyUpdateInterval = 0.14;
        _qualityBodyChangeDenominator = 14;
    } else if (_qualityLevel == 2) {
        _activeAnimationInterval = 1.0 / 45.0;
        _qualityAllowGlow = YES;
        _qualityMosaicEnabled = YES;
        _qualityHeadUpdateInterval = 0.10;
        _qualityBodyUpdateInterval = 0.18;
        _qualityBodyChangeDenominator = 18;
    } else if (_qualityLevel == 1) {
        _activeAnimationInterval = 1.0 / 30.0;
        _qualityAllowGlow = NO;
        _qualityMosaicEnabled = YES;
        _qualityHeadUpdateInterval = 0.14;
        _qualityBodyUpdateInterval = 0.24;
        _qualityBodyChangeDenominator = 26;
    } else {
        _activeAnimationInterval = 1.0 / 20.0;
        _qualityAllowGlow = NO;
        _qualityMosaicEnabled = YES;
        _qualityHeadUpdateInterval = 0.18;
        _qualityBodyUpdateInterval = 0.30;
        _qualityBodyChangeDenominator = 36;
    }
    
    if (!_isPreviewHost) {
        if (_qualityLevel >= 2) {
            _mosaicInterval = 45.0;
            _mosaicDuration = 4.0;
        } else if (_qualityLevel == 1) {
            _mosaicInterval = 45.0;
            _mosaicDuration = 4.0;
        } else {
            _mosaicInterval = 45.0;
            _mosaicDuration = 4.0;
        }
    }
    
    if (!_qualityMosaicEnabled) {
        // Do not force stop mosaic here to avoid interruption
        // _isMosaicMode = NO;
    }
    
    [self applyLegacyHostAnimationPolicy];
    
    // Never rebuild matrix during runtime quality adjustment
    // BOOL shouldRebuild = ...
    // if (shouldRebuild) [self initializeMatrix];
}

- (void)maybeAdjustQualityForCPUAtTime:(NSTimeInterval)currentTime
{
    if (!_isAnimatingActive) return;
    if (_isWallpaperHost && !_systemScreenSaverIsActive) return;
    
    NSTimeInterval minSampleInterval = 2.0;
    if (_lastCPUSampleTime > 0 && (currentTime - _lastCPUSampleTime) < minSampleInterval) return;
    _lastCPUSampleTime = currentTime;
    
    float cpu = [self currentProcessCPUUsagePercent];
    if (cpu < 0) return;
    
    NSTimeInterval minChangeInterval = 6.0;
    if (_lastQualityChangeTime > 0 && (currentTime - _lastQualityChangeTime) < minChangeInterval) return;
    
    float upper = _targetCPUPercent + 5.0f;
    float lower = _targetCPUPercent - 8.0f;
    
    if (cpu > upper && _qualityLevel > 0) {
        _lastQualityChangeTime = currentTime;
        [self applyQualityLevel:(_qualityLevel - 1)];
    } else if (cpu < lower && _qualityLevel < 3) {
        _lastQualityChangeTime = currentTime;
        [self applyQualityLevel:(_qualityLevel + 1)];
    }
}

- (void)applyLegacyHostAnimationPolicy
{
    NSTimeInterval desiredInterval = _activeAnimationInterval;
    if (_isWallpaperHost && !_systemScreenSaverIsActive) {
        desiredInterval = _idleAnimationInterval;
    }
    if (fabs(self.animationTimeInterval - desiredInterval) > 0.0001) {
        [self setAnimationTimeInterval:desiredInterval];
    }
}

- (void)systemScreenSaverDidStart:(NSNotification *)notification
{
    if (!_isWallpaperHost) return;
    if (_isPreviewHost) return;
    
    _systemScreenSaverIsActive = YES;
    _didHandleStopForCurrentSession = NO;
    _didScheduleStopAfterAlert = NO;
    _nextMosaicTriggerTime = 0;
    _mosaicEndTime = 0;
    _lastFrameTimestamp = CACurrentMediaTime();
    [self applyLegacyHostAnimationPolicy];
    if (_mosaicEnabled && _qualityMosaicEnabled) {
        [self triggerMosaicWithDuration:_mosaicDuration];
    }
    [self setNeedsDisplay:YES];
}

- (void)systemScreenSaverDidStop:(NSNotification *)notification
{
    if (!_isWallpaperHost) return;
    if (_isPreviewHost) return;
    
    if (_didHandleStopForCurrentSession) return;
    _didHandleStopForCurrentSession = YES;
    
    _systemScreenSaverIsActive = NO;
    _isMosaicMode = NO;
    _mosaicPoints = @[];
    _mosaicEndTime = 0;
    _nextMosaicTriggerTime = 0;
    _isFormingKeyword = NO;
    [_keywordStreams removeAllObjects];
    [self applyLegacyHostAnimationPolicy];
    [self unregisterSystemEventObservers];
    
    if (!_didScheduleStopAfterAlert) {
        _didScheduleStopAfterAlert = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopAnimation];
        });
    }
}

- (void)initializeMatrix {
    _streams = [NSMutableArray array];
    
    // Initialize keywords for periodic formation
    _keywords = @[@"2026", @"Hello World", @"Matrix", @"Code Rain", @"System"];
    if (!_aiQuotes) {
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
        _isMosaicMode = NO;
        _nextMosaicTriggerTime = 0;
        _mosaicEndTime = 0;
        _mosaicPoints = @[];
    }
    
    _currentKeywordIndex = 0;
    _lastKeywordTime = 0;
    _isFormingKeyword = NO;
    _keywordStreams = [NSMutableArray array];
    _startTimestamp = CACurrentMediaTime();
    
    _mosaicFont = [NSFont fontWithName:@"Courier-Bold" size:18.0];
    if (!_mosaicFont) _mosaicFont = [NSFont boldSystemFontOfSize:18.0];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    NSInteger layerCount = _qualityLayerCount > 0 ? _qualityLayerCount : (_isWallpaperHost ? 3 : 5);
    for (NSInteger layer = 0; layer < layerCount; layer++) {
        CGFloat zDepth = layerCount == 1 ? 1.0 : ((CGFloat)layer / (CGFloat)(layerCount - 1));
        
        CGFloat layerFontSize = 12.0 + (48.0 * (zDepth * zDepth));
        NSInteger columnCount = (NSInteger)(width / layerFontSize);
        if (columnCount <= 0) continue;
        
        uint32_t densityPercent = _qualityDensityPercent > 0 ? _qualityDensityPercent : (_isWallpaperHost ? 22 : 60);
        uint32_t layerPenalty = (uint32_t)(layer * (_isWallpaperHost ? 7 : 10));
        uint32_t probabilityPercent = densityPercent > layerPenalty ? (densityPercent - layerPenalty) : 5;
        
        for (NSInteger i = 0; i < columnCount; i++) {
            if (arc4random_uniform(100) < probabilityPercent) {
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
    [self triggerMosaicWithDuration:_mosaicDuration];
}

- (void)triggerMosaicWithDuration:(NSTimeInterval)duration
{
    if (!_mosaicEnabled) return;
    if (!_qualityMosaicEnabled) return;
    if (_availableQuotes.count == 0) {
        _availableQuotes = [_aiQuotes mutableCopy];
    }
    
    NSInteger index = arc4random_uniform((uint32_t)_availableQuotes.count);
    NSString *quote = _availableQuotes[index];
    [_availableQuotes removeObjectAtIndex:index];
    
    [self startMosaicWithText:quote];
    
    NSTimeInterval effectiveDuration = duration;
    if (effectiveDuration < 3.0) effectiveDuration = 3.0;
    _mosaicEndTime = CACurrentMediaTime() + effectiveDuration;
}

- (void)startMosaicWithText:(NSString *)text {
    _isMosaicMode = YES;
    
    // Generate grid points from text
    CGFloat screenWidth = self.bounds.size.width;
    CGFloat screenHeight = self.bounds.size.height;
    CGFloat maxTextWidth = screenWidth * 0.85; // Allow wrapping within 85% width
    
    // Dynamic font size calculation
    // Base heuristic: ScreenWidth / 5.0 for BIGGER text
    // or wrapped 2 lines.
    CGFloat fontSize = screenWidth / 5.0;
    if (fontSize > 400.0) fontSize = 400.0; // Cap max size
    if (fontSize < 50.0) fontSize = 50.0;   // Min size limit
    
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
    
    CGFloat maxHeight = screenHeight * 0.8;
    
    // Check if we need to scale down (height overflow)
    if (boundingRect.size.height > maxHeight) {
        CGFloat scale = maxHeight / boundingRect.size.height;
        fontSize *= scale;
        
        if (fontSize < 20.0) fontSize = 20.0; // Hard min limit
        
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
    CGFloat gridSize = 20.0;
    
    // Calculate scale factor (handling Retina displays)
    // bitmap.pixelsWide might be 2x or 3x of textSize.width
    CGFloat scaleX = (CGFloat)bitmap.pixelsWide / textSize.width;
    CGFloat scaleY = (CGFloat)bitmap.pixelsHigh / textSize.height;
    
    // Center the text on screen
    CGFloat startX = (screenWidth - textSize.width) / 2.0;
    CGFloat startY = (screenHeight - textSize.height) / 2.0;
    
    NSInteger cols = textSize.width / gridSize;
    NSInteger rows = textSize.height / gridSize;
    
    for (NSInteger y = 0; y < rows; y++) {
        for (NSInteger x = 0; x < cols; x++) {
            // Check pixel in the center of the grid cell
            // We must map point coordinates to pixel coordinates
            NSInteger pointX = x * gridSize + gridSize/2;
            NSInteger pointY = y * gridSize + gridSize/2; // Point coordinates (0 is bottom-left relative to image rect?)
            // Actually drawing in lockFocus uses standard coord system (0,0 bottom-left usually).
            // But we need to be careful about bitmap data layout.
            // Let's assume standard mapping first, but apply scale.
            
            NSInteger pixelX = pointX * scaleX;
            // NSImage coordinate (0,0) is bottom-left, but bitmap data usually starts top-left?
            // Let's rely on standard Quartz coordinate flipping if needed.
            // Actually, for NSBitmapImageRep from TIFF, (0,0) is usually top-left of the data buffer?
            // Let's try matching the flipped logic again if it was upside down before.
            // If user said "inverted" before, it means my previous (rows - 1 - y) was WRONG (or right?).
            // Wait, previous code:
            // pixelY = (rows - 1 - y) ... -> User said "inverted".
            // Then I changed to:
            // pixelY = y ... -> User said "inverted" (Wait, did they say inverted AFTER I changed it? Yes.)
            // So (rows - 1 - y) WAS correct? Or y is correct?
            // User said "警示词成了倒着的了" AFTER I changed it to `y * gridSize`.
            // So `y * gridSize` (bottom-up logic) made it upside down.
            // That means bitmap data is Top-Down.
            // So we need (rows - 1 - y) logic to flip it back upright?
            // NO. If I iterate y from 0..rows (Top..Bottom visually on screen),
            // and I want to sample Top..Bottom from image.
            // If image data is Top-Down (0 is top), then pixelY should just be y * scale.
            // If image data is Bottom-Up (0 is bottom), then pixelY should be (height - y) * scale.
            
            // Let's revert to the logic that matches screen Y (0 at bottom) to Image Y.
            // Screen: 0 is bottom.
            // Image Draw: 0 is bottom (NSImage).
            // Bitmap Data: 0 is Top (usually).
            // So if I want to draw at Screen Y=0 (Bottom), I need Image Pixel Y=Max (Bottom).
            // So PixelY should be (ImageHeight - PointY * scale).
            
            NSInteger pixelY = (textSize.height - pointY) * scaleY; 
            // Clamp
            if (pixelY < 0) pixelY = 0;
            if (pixelY >= bitmap.pixelsHigh) pixelY = bitmap.pixelsHigh - 1;
            
            if (pixelX >= bitmap.pixelsWide) continue;
            
            NSColor *color = [bitmap colorAtX:pixelX y:pixelY];
            if (color.brightnessComponent > 0.3) {
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
    _isAnimatingActive = YES;
    _lastFrameTimestamp = CACurrentMediaTime();
    [self registerSystemEventObserversIfNeeded];
    if (_isWallpaperHost && !_isPreviewHost) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!_isAnimatingActive) return;
            if (_systemScreenSaverIsActive) return;
            [self systemScreenSaverDidStart:nil];
        });
    }
    [self applyLegacyHostAnimationPolicy];
    if (!_isWallpaperHost && !_isPreviewHost && _mosaicEnabled && _qualityMosaicEnabled) {
        [self triggerMosaicWithDuration:_mosaicDuration];
    }
}

- (void)stopAnimation
{
    [super stopAnimation];
    _isAnimatingActive = NO;
    _isMosaicMode = NO;
    _mosaicPoints = @[];
    _mosaicEndTime = 0;
    _nextMosaicTriggerTime = 0;
    _isFormingKeyword = NO;
    [_keywordStreams removeAllObjects];
    [self unregisterSystemEventObservers];
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
    BOOL allowGlow = !_isWallpaperHost && !_isPreviewHost && _qualityAllowGlow;
    
    NSMutableDictionary *sharedHeadAttrs = [NSMutableDictionary dictionaryWithCapacity:2];
    sharedHeadAttrs[NSForegroundColorAttributeName] = whiteColor;
    
    NSMutableDictionary *sharedCharAttrs = [NSMutableDictionary dictionaryWithCapacity:2];

    for (MatrixStream *stream in _streams) {
        // Optimization: Cull off-screen streams entirely
        if (stream.yPosition > self.bounds.size.height + stream.streamLength * stream.fontSize ||
            stream.yPosition < -(stream.streamLength * stream.fontSize)) {
            continue;
        }

        // Apply glow only for foreground layers or glitch streams
        if (allowGlow && (stream.zDepth > 0.8 || stream.isGlitch)) {
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
        sharedHeadAttrs[NSFontAttributeName] = stream.font;
        [stream.headCharacter drawAtPoint:NSMakePoint(stream.xPosition, stream.yPosition) withAttributes:sharedHeadAttrs];
        
        // Draw Body Characters
        NSColor *baseColor = stream.isGlitch ? glitchRed : matrixGreen;
        sharedCharAttrs[NSFontAttributeName] = stream.font;
        
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
            sharedCharAttrs[NSForegroundColorAttributeName] = color;
            
            NSString *charString = (i < stream.characters.count) ? stream.characters[i] : @"";
            [charString drawAtPoint:NSMakePoint(stream.xPosition, charY) withAttributes:sharedCharAttrs];
        }
    }
    
    // Draw keyword streams
    if (allowGlow) [strongGlowShadow set];
    
    for (MatrixStream *stream in _keywordStreams) {
        NSMutableDictionary *keywordAttrs = [NSMutableDictionary dictionaryWithCapacity:2];
        keywordAttrs[NSFontAttributeName] = stream.font;
        keywordAttrs[NSForegroundColorAttributeName] = whiteColor;
        for (int i = 0; i < stream.streamLength; i++) {
            CGFloat charY = stream.yPosition + (i * stream.fontSize);
            
            if (charY > self.bounds.size.height || charY < -stream.fontSize) {
                continue;
            }
            
            NSString *charString = (i < stream.characters.count) ? stream.characters[i] : @"";
            [charString drawAtPoint:NSMakePoint(stream.xPosition, charY) withAttributes:keywordAttrs];
        }
    }
    
    // Reset shadow
    [noShadow set];
    
    // Draw Mosaic Overlay
    if (_isMosaicMode && _mosaicPoints.count > 0) {
        if (allowGlow) [strongGlowShadow set];
        
        NSDictionary *mosaicAttrs = @{
            NSFontAttributeName: _mosaicFont,
            NSForegroundColorAttributeName: matrixGreen
        };
        
        NSDictionary *shadowAttrs = @{
            NSFontAttributeName: _mosaicFont,
            NSForegroundColorAttributeName: [matrixGreen colorWithAlphaComponent:0.4]
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
            
            // Draw 3 layers for thickness as requested
            // Layer 1: Left
            [charStr drawAtPoint:NSMakePoint(p.x - 5.0, p.y) withAttributes:mosaicAttrs];
            // Layer 2: Right
            [charStr drawAtPoint:NSMakePoint(p.x + 5.0, p.y) withAttributes:mosaicAttrs];
            // Layer 3: Center
            [charStr drawAtPoint:p withAttributes:mosaicAttrs];
        }
        
        [noShadow set];
    }
}

- (void)animateOneFrame
{
    if (!_isAnimatingActive) return;
    CGFloat height = self.bounds.size.height;
    NSTimeInterval currentTime = CACurrentMediaTime();
    [self maybeAdjustQualityForCPUAtTime:currentTime];
    if (_isWallpaperHost && !_isPreviewHost && !_systemScreenSaverIsActive) {
        _lastFrameTimestamp = currentTime;
        return;
    }
    NSTimeInterval deltaTime = 0;
    if (_lastFrameTimestamp > 0) {
        deltaTime = currentTime - _lastFrameTimestamp;
    }
    _lastFrameTimestamp = currentTime;
    if (deltaTime > 0.25) deltaTime = 0.25;
    
    if (_mosaicEnabled && _qualityMosaicEnabled) {
        if (_isMosaicMode) {
            if (_mosaicEndTime > 0 && currentTime >= _mosaicEndTime) {
                [self stopMosaic];
                _nextMosaicTriggerTime = currentTime + _mosaicInterval;
                _mosaicEndTime = 0;
            } else {
                [self setNeedsDisplay:YES];
                return;
            }
        } else {
            if (_nextMosaicTriggerTime == 0) {
                // If it's the first run, trigger immediately (or with a tiny delay)
                // instead of waiting for the full interval.
                _nextMosaicTriggerTime = currentTime + 0.1;
            }
            if (currentTime >= _nextMosaicTriggerTime) {
                [self triggerMosaic];
            }
        }
    } else if (_isMosaicMode) {
        [self stopMosaic];
    }
    
    // Check if 10 seconds have passed for keyword formation (more frequent)
    if (currentTime - _lastKeywordTime > _keywordInterval && !_isFormingKeyword) {
        _isFormingKeyword = YES;
        _lastKeywordTime = currentTime;
        [self formKeyword];
    }
    
    NSTimeInterval headUpdateInterval = _qualityHeadUpdateInterval;
    NSTimeInterval bodyUpdateInterval = _qualityBodyUpdateInterval;
    uint32_t bodyChangeDenominator = _qualityBodyChangeDenominator;
    
    // Update all streams
    for (MatrixStream *stream in _streams) {
        [stream updateWithScreenHeight:height
                             deltaTime:deltaTime
                           currentTime:currentTime
                      headUpdateEvery:headUpdateInterval
                      bodyUpdateEvery:bodyUpdateInterval
                  bodyChangeDenominator:bodyChangeDenominator];
    }
    
    // Update keyword streams if forming
    if (_isFormingKeyword) {
        for (MatrixStream *stream in _keywordStreams) {
            [stream updateWithScreenHeight:height
                                 deltaTime:deltaTime
                               currentTime:currentTime
                          headUpdateEvery:headUpdateInterval
                          bodyUpdateEvery:bodyUpdateInterval
                      bodyChangeDenominator:bodyChangeDenominator];
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
