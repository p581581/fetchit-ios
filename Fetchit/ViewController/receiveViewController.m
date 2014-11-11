//
//  receiveViewController.m
//  SocketFileTest1
//
//  Created by 581 on 2014/4/21.
//  Copyright (c) 2014年 581. All rights reserved.
//
#import <AssetsLibrary/ALAssetsLibrary.h>
#import "receiveViewController.h"
#import "ViewController.h"
#import "progressButton.h"
#import "Request.h"
#import "Server.h"
#import "Fetchit.h"

#define BUFFER_SIZE 4096
#define SERVER_PORT @22750
#define ROOT_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

// 記錄當前傳輸狀態
enum : int {
    READ_STREAM_FILE_COUNT ,        // 檔案數量
    READ_STREAM_FILE_LENGTH,        // 各別檔案長度
    READ_STREAM_FILENAME_LENGTH,    // 檔名長度
    READ_STREAM_FILE_NAME,          // 檔案名稱
    READ_STREAM_FILE_CONTENT        // 檔案內容 (Bytes)
} READ_STREAM_STATE;

// weak self
receiveViewController const* Self;

@interface receiveViewController () <FetchitServerDelegate> {
    Byte buffer[BUFFER_SIZE];
    int64_t stageRecivedLength;
    int64_t fileRecivedLength;
    NSUInteger fileCount;
    NSUInteger fileCompletedCount;
    int64_t fileLength;
    int64_t filenameLength;
    NSString *fileName;
    
    receiveViewController const* Self;
}

@property (weak, nonatomic) IBOutlet UILabel *centerText;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) Server *server;

@property UIImage *image;
@property NSMutableData *data;      // 接收檔案串流

@property NSString* code;
@property NSThread *receiveThread;  // 更新進度執行緒

@property (strong, nonatomic) NSMutableArray* progresses;
@property (strong, nonatomic) NSMutableArray* files;
@property (strong, nonatomic) NSMutableArray* filenames;


@end

@implementation receiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    Self = self;
    [ViewController setViewGradient:self.view];
    _centerText.numberOfLines = 0;
    
    _progresses = [[NSMutableArray alloc] init];
    _files = [[NSMutableArray alloc] init];
    _filenames = [[NSMutableArray alloc]init];
}

- (void) viewWillDisappear:(BOOL)animated {
    if (_server) {
        [_server close];
        _server = nil;
    }

    if (_code) {
        [[Request defaultRequest] getWithURL:FETCHIT_API_URL parameters:@{ @"action": @"delete", @"key": FETCHIT_API_KEY, @"id": _code } completion:AFCALLBACK_C {
            NSLog(@"%@",responseData);
            _code = nil;
        }];
    }
    
    [_filenames removeAllObjects];
    [_progresses removeAllObjects];
    [_files removeAllObjects];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma action

- (IBAction)backAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)chooseFile:(id)sender {
}

- (IBAction)receiveAction:(id)sender {
    
    [_server close];
    _server = [[Server alloc] initWithPort:[SERVER_PORT intValue]];
    _server.delegate = self;
    
    [self activityIndicatorAnimation:YES];
    _centerText.hidden = NO;
    
    NSArray *ips = [Fetchit getIPAddress];
    NSArray * ip_ports = [Fetchit ArrayWithIpPort:ips];
    
    // request for getting code
    [[Request defaultRequest] getWithURL:FETCHIT_API_URL parameters:@{ @"action": @"encode", @"key": FETCHIT_API_KEY, @"ip": [Request JSONArrayWithArray:ip_ports] } completion:AFCALLBACK_C {
        
        NSString * text = @"Your receiving code is\n\n%@";
        _code = [responseData valueForKey:@"result"];
        if (_code) {
            text = [NSString stringWithFormat:text, _code];
        } else {
            text = [NSString stringWithFormat:text, [Fetchit stringwithIpArray:ips]];
        }
        [self reviseCenterText:text];
        [self activityIndicatorAnimation:NO];
    }];
    
    _receiveThread = [[NSThread alloc] initWithTarget:self selector:@selector(setThreadInRunMode) object:nil];
    [_receiveThread start];
}

# pragma receive data

- (void)setThreadInRunMode
{
    _receiveThread.name = @"581";
    // adding some input source, that is required for runLoop to runing
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    
    // starting infinite loop which can be stopped by changing the shouldKeepRunning's value
    while ([_server isActive] && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]){
    }
}

-(void) HasBytesAvailable: (NSInputStream*) stream {
    NSLog(@"HasBytesAvailable");
    long currentReceived = 0;
    long long int remain;
    switch (READ_STREAM_STATE) {
        case READ_STREAM_FILE_COUNT: // 讀取檔案數量
            
            // 讀取串流
            currentReceived = [stream read:buffer + stageRecivedLength  maxLength: 4 - (int) stageRecivedLength];
            
            // error
            if(currentReceived == -1){
                @throw [[NSException alloc]initWithName:@"Read error." reason:@"buffer overflow." userInfo:nil];
            }
            
            stageRecivedLength += currentReceived;
            // Convert bytes to integer
            if (stageRecivedLength == 4) {
                stageRecivedLength=  0;
                fileCount = (buffer[0] << 24) + (buffer[1] << 16) + (buffer[2] << 8) + buffer[3];
                fileCompletedCount = 0;
                NSLog(@"file count :%lu", (unsigned long)fileCount);
                [self performSelector:@selector(createProgress:) onThread:_receiveThread withObject:@(fileCount) waitUntilDone:NO ];
                
                READ_STREAM_STATE++;
            }
            break;
            
        case READ_STREAM_FILE_LENGTH:  // 讀取個別檔案長度
            
            // 讀取串流
            currentReceived = [stream read:buffer + stageRecivedLength  maxLength: 8 - (int) stageRecivedLength];
            
            // error
            if(currentReceived == -1){
                @throw [[NSException alloc]initWithName:@"Read error." reason:@"buffer overflow." userInfo:nil];
            }
            
            stageRecivedLength += currentReceived;
            // Convert bytes to integer
            if (stageRecivedLength == 8) {
                stageRecivedLength=  0;
                fileLength = ((long long) buffer[0] << 56) + ((long long) buffer[1] << 48) + ((long long) buffer[2] << 40) + ((long long) buffer[3] << 32) + ((long long) buffer[4] << 24) + ((long long) buffer[5] << 16) + ((long long) buffer[6] << 8) + (long long) buffer[7];
                NSLog(@"file length :%lld", fileLength);
                READ_STREAM_STATE++;
            }
            
            break;
            
        case READ_STREAM_FILENAME_LENGTH: // 讀取檔名長度
            
            // 讀取串流
            currentReceived = [stream read:buffer + stageRecivedLength  maxLength: 2 - (int) stageRecivedLength];
            
            // error
            if(currentReceived == -1){
                @throw [[NSException alloc]initWithName:@"Read error." reason:@"buffer overflow." userInfo:nil];
            }
            
            stageRecivedLength += currentReceived;
            // Convert bytes to integer
            if (stageRecivedLength == 2) {
                stageRecivedLength=  0;
                
                filenameLength = (buffer[0] << 8) + buffer[1];
                
                NSLog(@"file name length :%lld", filenameLength);
                READ_STREAM_STATE++;
            }
            
            
            break;
            
        case READ_STREAM_FILE_NAME: // 讀取檔名
            
            // 讀取串流
            currentReceived = [stream read:buffer + stageRecivedLength  maxLength: filenameLength - (long long) stageRecivedLength];
            
            // error
            if(currentReceived == -1){
                @throw [[NSException alloc]initWithName:@"Read error." reason:@"buffer overflow." userInfo:nil];
            }
            
            stageRecivedLength += currentReceived;
            // Convert bytes to NSString
            if (stageRecivedLength == filenameLength) {
                stageRecivedLength=  0;
                
                
                fileName = [[NSString alloc] initWithData:[[NSData alloc]initWithBytesNoCopy:(void*) buffer length:filenameLength freeWhenDone:NO] encoding:NSUTF8StringEncoding];
                
                NSLog(@"file name :%@", fileName);
                READ_STREAM_STATE++;
                _data = [[NSMutableData alloc] init];
                
                
                // 更新進度條資訊
                NSDictionary * dict = @{@"index":@(fileCompletedCount),@"title":fileName, @"fileSize":[NSString stringWithFormat:@"%lld",fileLength]};
                
                    [self performSelector:@selector(setProgress:) onThread:_receiveThread withObject:dict waitUntilDone:NO ];
            }
            
            break;
            
        case READ_STREAM_FILE_CONTENT: // 讀取檔案內容
            
            // 計算未傳檔案大小，並決定這次接收長度
            remain = fileLength - fileRecivedLength;
            int length = (remain >= BUFFER_SIZE)?BUFFER_SIZE:(int)remain;
            
            // 讀取串流
            currentReceived = [stream read:buffer + stageRecivedLength  maxLength: length - stageRecivedLength];
            
            // error
            if(currentReceived == -1){
                @throw [[NSException alloc]initWithName:@"Read error." reason:@"buffer overflow." userInfo:nil];
            }
            
            stageRecivedLength += currentReceived;
            fileRecivedLength += currentReceived;
            
            NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.003 ];
            [NSThread sleepUntilDate:future];
            
            NSDictionary * dict = @{@"index":@(fileCompletedCount),@"progress":@((float)fileRecivedLength / (float) fileLength)};
            
            [self performSelector:@selector(updateProgress:) onThread:_receiveThread withObject: dict waitUntilDone:NO];
            
            if (stageRecivedLength == BUFFER_SIZE || fileRecivedLength == fileLength) {
                
                stageRecivedLength =  0;
                
                [_data appendBytes:buffer length:length];
                
                
                if (fileRecivedLength == fileLength) {
                    
                    fileRecivedLength = 0;
                    
                    [_files addObject:_data];
                    [_filenames addObject:[NSString stringWithString:fileName]];
                    
                    [self performSelector:@selector(notifyProgressEnd:) onThread:_receiveThread withObject:@(fileCompletedCount) waitUntilDone:NO ];
                    
                    fileCompletedCount++;
                    NSLog(@"%lu",(unsigned long)fileCompletedCount);
                    
                    if (fileCompletedCount == fileCount) {
                        READ_STREAM_STATE = READ_STREAM_FILE_COUNT;
                        [_server close];
                        _server = nil;
                    } else if (fileCompletedCount < fileCount) {
                        READ_STREAM_STATE = READ_STREAM_FILE_LENGTH;
                    }
                }
            }
            
        break;
    }
}

# pragma modify and update UI in main thread

- (void) createProgress:(NSNumber*) count {
    
    int file_count = [count intValue];
    
    for (int i = 0; i < file_count; i++) {
        progressButton *progress = [[progressButton alloc] initWithFrame:
                                    CGRectMake(0, 40 + (90 * i), 700, 90)];
        progress.tag = i;
        progress.hidden = YES;
        [self.view addSubview:progress];
        [_progresses addObject:progress];
        [progress addTarget:self action:@selector(chooseFile:) forControlEvents:UIControlEventTouchUpInside];
    }
    _centerText.hidden = YES;
}

- (void) setProgress:(NSDictionary*) dict{
    
    NSLog(@"setFileinfo");
    
    int index = [dict[@"index"] intValue];
    
    progressButton * tmp = _progresses[index];
    tmp.hidden = NO;
    [tmp transferBegin];
    [tmp setFileTitle:dict[@"title"]];
    [tmp setFileSize:dict[@"fileSize"]];
}

- (void) updateProgress: (NSDictionary*) dict{
    
    NSLog(@"updateprogress: %f",[dict[@"progress"] floatValue]);
    
    int index = [dict[@"index"] intValue];
    progressButton * tmp = _progresses[index];
    [tmp setProgress:[dict[@"progress"] floatValue]];
}

- (void) notifyProgressEnd: (NSNumber*) _index{
    
    NSLog(@"file end");
    int index = [_index intValue];
    progressButton * tmp = _progresses[index];
    [tmp transferDidEnd];
    [self saveImageToLibrary:_files[index] fileName:_filenames[index]];
}

- (void) reviseCenterText: (NSString*) text{
    dispatch_async(dispatch_get_main_queue(), ^() {
        _centerText.text = text;
    });
}

-(void) activityIndicatorAnimation:(BOOL) animation {
    
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (animation) {
            [_activityIndicator startAnimating];
        } else {
            [_activityIndicator stopAnimating];
        }
    });
}

# pragma saving files

-(BOOL) saveFileToDocument: (NSData*) fileData fileName: (NSString*) name {

    NSString* filePath = [ROOT_PATH stringByAppendingPathComponent:name];
    
     return [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileData attributes:nil];
 }

-(void) saveImageToLibrary: (NSData*) fileData fileName: (NSString*) name {
    
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    
    [assetsLibrary writeImageDataToSavedPhotosAlbum:fileData metadata:nil completionBlock: ^(NSURL *assetURL, NSError *error) {
            if  (error) {
                    NSLog(@ "Save image fail:%@" ,error);
                }  else  {
                    NSLog(@ "Save image succeed.");
                }
            }
     ];
}
@end
