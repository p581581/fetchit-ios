//
//  sendViewController.m
//  SocketFileTest1
//
//  Created by 581 on 2014/4/16.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import "sendViewController.h"
#import "ViewController.h"
#import "progressButton.h"
#import "Request.h"
#import "Fetchit.h"
#import "Client.h"

#import <arpa/inet.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>

#define BUFFER_SIZE 4096
#define SERVER_PORT @22750

@interface sendViewController () <UIImagePickerControllerDelegate, UIAlertViewDelegate, ELCImagePickerControllerDelegate> {
    UIPopoverController *popover;
    NSUInteger fileCount;

}

@property (weak, nonatomic) IBOutlet UIButton *centerAddBtn;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *sendFileBtn;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) Client *client;

@property NSObject *sendObject;
@property NSMutableArray* progresses;
@property NSMutableArray* files;


@end

@implementation sendViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [ViewController setViewGradient:self.view];
    self.sendFileBtn.hidden = YES;
    fileCount = 0;
    
    self.progresses = [[NSMutableArray alloc] init];
    self.files = [[NSMutableArray alloc] init];
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

// 設定傳送代碼或ip
- (IBAction)sendAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    
    [alertView setDelegate:self];
    alertView.title = @"Set up";
    alertView.message = @"Please input the receiving code or IP.";
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView addButtonWithTitle:@"OK"];
    [alertView addButtonWithTitle:@"Cancel"];
    
    UITextField *t  = [alertView textFieldAtIndex:0];
    t.placeholder = @"code or ip";
    
    [alertView show];
    
}

// 加入要傳送的檔案
- (IBAction)addAction:(id)sender {
    
    ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
    elcPicker.maximumImagesCount = 100;
    elcPicker.returnsOriginalImage = YES; //Only return the fullScreenImage, not the fullResolutionImage
	elcPicker.imagePickerDelegate = self;
    
    popover = [[UIPopoverController alloc]initWithContentViewController:elcPicker];
    UIButton *btn = sender;
    CGRect rect = btn.frame;
    [popover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark ELCImagePickerControllerDelegate Methods : pick multiple photos

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [popover dismissPopoverAnimated:YES];
    self.sendFileBtn.hidden = NO;
    self.centerAddBtn.hidden = YES;
//    self.progress.hidden = NO;
	
    int file_count = (int)[info count];
    
    for (int i = 0; i < file_count; i++) {
        
        NSDictionary *dict = info[i];
        progressButton *progress = [[progressButton alloc] initWithFrame:CGRectMake(0, 40 + (90 * (i + fileCount)), self.view.frame.size.width, 90)];
        progress.tag = i;
//        progress.hidden = YES;
        [progress transferBegin];
        [progress setFileTitle:[NSString stringWithFormat:@"DSC_5810%lu.jpg", (int)i+fileCount]];
        [self.view addSubview:progress];
        [self.progresses addObject:progress];
        
        NSLog(@"%@",[dict valueForKey:UIImagePickerControllerReferenceURL]);
        [self.files addObject:[dict objectForKey:UIImagePickerControllerOriginalImage]];
        
    }
    
    fileCount += file_count;
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [popover dismissPopoverAnimated:YES];
}

# pragma UIAlertView Delegate Method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{   
    //Click OK button
    if(buttonIndex==0) {
        _client = [Client defaultClient];
        NSString *text = [[alertView textFieldAtIndex:0].text uppercaseString];
        
        if([Fetchit validateIP:text]) {
            NSString *port = [NSString stringWithFormat:@"%@",SERVER_PORT];
            [_client connectionWithIp:text port:port timeOut:1];
        } else {
            
            [[Request defaultRequest] getWithURL:FETCHIT_API_URL parameters:@{ @"action": @"decode", @"key": FETCHIT_API_KEY, @"id": text } completion:AFCALLBACK_C {
                
                if (responseData[@"result"]) {
                    NSArray *ip_ports = [Request JSONObjectWithString:responseData[@"result"]];
                    
                    [self activityIndicatorAnimation:YES];
                    
                    for (id ip_port in ip_ports) {
                        if ([_client connectionWithIp:ip_port[@"ip"] port:ip_port[@"port"] timeOut:0.5]) {
                            NSLog(@"%@", ip_port[@"ip"]);
                            NSThread* sendFilesThread = [[NSThread alloc] initWithTarget:self selector:@selector(sendFile:) object:(UIImage*)self.sendObject];
                            [sendFilesThread start];
                            break;
                        }
                    }
                    
                    [self activityIndicatorAnimation:NO];
                } else {
                    NSLog(@"%@", responseData);
                }
            }];
        }
    }
}

# pragma sending files

- (void) sendFile: (UIImage*) image{
    
    NSLog(@"sending...");
    
    [self performSelectorOnMainThread:@selector(notifyProgressBegin) withObject:nil waitUntilDone:NO];
    
    Byte bufferFileCount[4];
    bufferFileCount[0] = (Byte) (fileCount >> 24);
    bufferFileCount[1] = (Byte) ((fileCount << 8) >> 24);
    bufferFileCount[2] = (Byte) ((fileCount << 16) >> 24);
    bufferFileCount[3] = (Byte) ((fileCount << 24) >> 24);
    
    // send number of file
    [_client.outputStream write:bufferFileCount maxLength:4];
    
    for (NSInteger fileCompleteCount = 0;  fileCompleteCount < fileCount; fileCompleteCount++) {
        
        NSData *imageData = UIImageJPEGRepresentation(self.files[fileCompleteCount], 1.0);
        NSString * name = [NSString stringWithFormat:@"DSC_5810%ld.jpg",fileCompleteCount + 1];

        NSString * rootPath =[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        
        NSString* filePath = [rootPath stringByAppendingPathComponent:name];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        [fm createFileAtPath:filePath contents:imageData attributes:nil];
        
        
        NSDictionary *fileAttr = NULL;
        
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:filePath isDirectory:&isDir]) {
            fileAttr = [fm attributesOfItemAtPath:filePath error:NULL];
        }else {
            NSLog(@"erorr!!!!!");
            return;
        }
        
        //取得檔案大小
        unsigned long long fileLength = [[fileAttr objectForKey:NSFileSize] longLongValue];
        
        Byte bufferFileLength[8];
        bufferFileLength[0] = (Byte) (fileLength >> 56);
        bufferFileLength[1] = (Byte) ((fileLength << 8) >> 56);
        bufferFileLength[2] = (Byte) ((fileLength << 16) >> 56);
        bufferFileLength[3] = (Byte) ((fileLength << 24) >> 56);
        bufferFileLength[4] = (Byte) ((fileLength << 32) >> 56);
        bufferFileLength[5] = (Byte) ((fileLength << 40) >> 56);
        bufferFileLength[6] = (Byte) ((fileLength << 48) >> 56);
        bufferFileLength[7] = (Byte) ((fileLength << 56) >> 56);
        
        //取得檔案名稱
        NSString * fileName = [filePath lastPathComponent];
        NSData * b = [fileName dataUsingEncoding:NSUTF8StringEncoding];
        Byte *bufferFileName = (Byte *)[b bytes];
        int fileNameLength = (int)[b length];
        
        //名稱長度
        Byte bufferFileNameLength [2];
        bufferFileNameLength[0] = (Byte) (fileNameLength >> 8);
        bufferFileNameLength[1] = (Byte) ((fileNameLength << 8) >> 8);
        
        //send header
        [_client.outputStream write:bufferFileLength maxLength:8];
        [_client.outputStream write:bufferFileNameLength maxLength:2];
        [_client.outputStream write:bufferFileName maxLength:fileNameLength];
        
        
        NSDictionary* dict = @{@"index":@(fileCompleteCount),@"title":fileName, @"fileSize":[NSString stringWithFormat:@"%llu",fileLength]};
        // set the UIProgressView on Main Thread
        [self performSelectorOnMainThread:@selector(setProgress:) withObject:dict waitUntilDone:NO];
        
//        //讀取檔案
//        NSFileHandle * fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
//        
//        //記錄傳送多少Byte
//        unsigned long long  sum = 0;
//        int length;
//        NSData *buffer;
//        
//        //每次傳送4096Bytes
//        while (sum < fileLength) {
//            
//            //讀取4096Bytes
//            buffer = [fileHandle readDataOfLength:BUFFER_SIZE];
//            length = (int)[buffer length]; //目前長度大小
//            
//            //輸出串流並確保有完整寫入
//            for(
//                NSInteger write_count = 0;
//                write_count < length;
//                write_count += [_client.outputStream write: [buffer bytes] + write_count maxLength:length - write_count]
//            );
//            
//            //加總長度
//            sum += length;
//            
////            NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.01 ];
////            [NSThread sleepUntilDate:future];
//            
//            NSDictionary * dict = @{@"index":@(fileCompleteCount),@"progress":@((float)sum / (float) fileLength)};
//            
//            // Update the UIProgressView on Main Thread
//            [self performSelectorOnMainThread:@selector(updateProgress:) withObject:dict waitUntilDone:NO];
//        }
//        
//        [fileHandle closeFile];
//        // Update the UIProgressView on Main Thread
//        [self performSelectorOnMainThread:@selector(notifyProgressEnd:) withObject:@(fileCompleteCount) waitUntilDone:NO];
//        NSLog(@"close file");
    }
    
    
    for (NSInteger fileCompleteCount = 0;  fileCompleteCount < fileCount; fileCompleteCount++) {
        
        NSString * name = [NSString stringWithFormat:@"DSC_5810%ld.jpg",fileCompleteCount + 1];
        NSString * rootPath =[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString* filePath = [rootPath stringByAppendingPathComponent:name];
        
        //讀取檔案
        NSFileHandle * fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileLength = [fileSizeNumber longLongValue];
        
        //記錄傳送多少Byte
        unsigned long long  sum = 0;
        int length;
        NSData *buffer;
        
        //每次傳送4096Bytes
        while (sum < fileLength) {
            
            //讀取4096Bytes
            buffer = [fileHandle readDataOfLength:BUFFER_SIZE];
            length = (int)[buffer length]; //目前長度大小
            
            //輸出串流並確保有完整寫入
            for(
                NSInteger write_count = 0;
                write_count < length;
                write_count += [_client.outputStream write: [buffer bytes] + write_count maxLength:length - write_count]
                );
            
            //加總長度
            sum += length;
            
            //            NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.01 ];
            //            [NSThread sleepUntilDate:future];
            
            NSDictionary * dict = @{@"index":@(fileCompleteCount),@"progress":@((float)sum / (float) fileLength)};
            
            // Update the UIProgressView on Main Thread
            [self performSelectorOnMainThread:@selector(updateProgress:) withObject:dict waitUntilDone:NO];
        }
        
        [fileHandle closeFile];
        // Update the UIProgressView on Main Thread
        [self performSelectorOnMainThread:@selector(notifyProgressEnd:) withObject:@(fileCompleteCount) waitUntilDone:NO];
        NSLog(@"close file");
        
        Byte checksum[] = {0,0,0,0,0,0,0,0};
        [_client.outputStream write: checksum maxLength:8];
    }
    
    [_client close];
}

# pragma modify and update UI in main thread

- (void) notifyProgressBegin {
    for(progressButton* tmp in self.progresses){
        [tmp transferBegin];
    }
}

- (void) setProgress:(NSDictionary*) dict{
    
    NSLog(@"setFileinfo");
    
    int index = [dict[@"index"] intValue];
    
    progressButton * tmp = self.progresses[index];
    tmp.hidden = NO;
    [tmp setFileTitle:dict[@"title"]];
    [tmp setFileSize:dict[@"fileSize"]];
}

- (void) updateProgress: (NSDictionary*) dict{
    
    NSLog(@"updateprogress: %f",[dict[@"progress"] floatValue]);
    
    int index = [dict[@"index"] intValue];
    progressButton * tmp = self.progresses[index];
    [tmp setProgress:[dict[@"progress"] floatValue]];
}

- (void) notifyProgressEnd: (NSNumber*) index{
    NSLog(@"file end");
    progressButton * tmp = self.progresses[[index intValue]];
    [tmp transferDidEnd];
}

- (void) cleanProgress {
    
    for(int i = 0; i<self.progresses.count ; i++) {
        progressButton* tmp =  self.progresses[i];
        tmp.hidden = YES;
    }
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

@end
