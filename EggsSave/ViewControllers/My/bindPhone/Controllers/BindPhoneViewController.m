//
//  BindPhoneViewController.m
//  EggsSave
//
//  Created by 郭洪军 on 1/4/16.
//  Copyright © 2016 Adwan. All rights reserved.
//

#import "BindPhoneViewController.h"
#import "CommonDefine.h"
#import "LoginManager.h"
#import "CommonMethods.h"
#import "CCLocationManager.h"
#import "User.h"

#include <dlfcn.h>

#define PRIVATE_PATH  "/System/Library/PrivateFrameworks/CoreTelephony.framework/CoreTelephony"

@interface BindPhoneViewController ()
{
    UITextField* activeField;
    NSTimer*     _jishiTimer;
    
    int          _daojishiTime;
}
@property (weak, nonatomic) IBOutlet UITextField *phonenumTextField;
@property (weak, nonatomic) IBOutlet UITextField *myAuthCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneAuthCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *comfirmPasswordTextField;
@property (weak, nonatomic) IBOutlet UILabel *authCodeLabel;
@property (weak, nonatomic) IBOutlet UIButton *getSMSButton;
@property (weak, nonatomic) IBOutlet UILabel *getSMSLabel;
- (IBAction)getSMSAuthCode:(id)sender;

@property (copy, nonatomic) NSString* authCode;
@property (strong, nonatomic) id authcodeObserver;
@property (copy, nonatomic) NSString* cityName;
- (IBAction)signUpConfirm:(id)sender;

@property (strong, nonatomic) id bindPhoneObserver;

@end

@implementation BindPhoneViewController

- (void)viewWillAppear:(BOOL)animated
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    self.authcodeObserver = [center addObserverForName:NSUserGetAuthCodeNotification object:nil
                                                queue:mainQueue usingBlock:^(NSNotification *note) {
                                                    
                                                    NSDictionary* dict = note.userInfo;
                                                    
                                                    NSString* random = dict[@"random"];
                                                    self.authCode = random;
                                                    
                                                    [self.authCodeLabel setText:random];
                                                    
                                                }];
    
    self.bindPhoneObserver = [center addObserverForName:NSUserBindPhoneNotification object:nil queue:mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSDictionary* dict = note.userInfo;
        
        int result = [dict[@"result"] intValue];
        
        if (result == 1) {
            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"手机绑定成功" message:@"您的手机号已经成功绑定，可以用手机号登录" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            alert.tag = 601;
            [alert show];
            
        }else
        {
            UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"手机绑定失败" message:@"您输入的手机号已经存在，请换个手机号再试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            alert.tag = 602;
            [alert show];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.authcodeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.bindPhoneObserver];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    
    self.title = @"手机号绑定";
    
    self.tableView.backgroundColor = [UIColor colorWithRed:(245 / 255.0) green:(245 / 255.0) blue:(245 / 255.0) alpha:1];
    
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    
    [self setUpHeader];
    
    [self.authCodeLabel setBackgroundColor:[UIColor lightGrayColor]];
    
    [self registerForKeyboardNotifications];
    
    _phonenumTextField.delegate = self;
    _myAuthCodeTextField.delegate = self;
    _passwordTextField.delegate =self;
    _comfirmPasswordTextField.delegate = self;
    
    _daojishiTime = 0;
    _getSMSLabel.hidden = YES;
    
    [self getAddress];
    
    [self getCity];
}

-(void)getAddress
{
    self.cityName = @"北京市";
    
    if (IS_IOS8) {
        
        [[CCLocationManager shareLocation]getAddress:^(NSString *addressString) {
            DLog(@"市：%@",addressString);
            
            if (addressString) {
                self.cityName = addressString;
            }else
            {
                self.cityName = @"北京市";
            }
            
        }] ;
        
    }
}

-(void)getCity
{
    //    __block __weak PersonalMessageViewController *wself = self;
    
    if (IS_IOS8) {
        
        [[CCLocationManager shareLocation]getCity:^(NSString *cityString) {
            DLog(@"省：%@",cityString);
            //            [wself setLabelText:cityString];
            
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpHeader
{
    UIView* headView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 30)];
    [headView setBackgroundColor:[UIColor colorWithRed:(235 / 255.0) green:(235 / 255.0) blue:(235 / 255.0) alpha:1]];
    
    UILabel* wordLable = [[UILabel alloc]initWithFrame:CGRectMake(10, 5, SCREEN_WIDTH - 20, 20)];
    [wordLable setFont:[UIFont systemFontOfSize:12]];
    [wordLable setText:@"为保证能安全登录，顺利提现，请设置手机号密码"];
    [headView addSubview:wordLable];
    
    self.tableView.tableHeaderView = headView;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *checkString;
    if (textField == _phonenumTextField) {
        if (range.location == 11) {
            return NO;
        }else{
            
            if (![string isEqualToString:@""]) {
                checkString=[self.phonenumTextField.text stringByAppendingString:string];
            }else{
                checkString=[checkString stringByDeletingLastPathComponent];
            }
            
            if ([self isMobileNumber:checkString]) {
                DLog(@"号码满足");
                //再次发送请求，获取验证码
                [[LoginManager getInstance]getAuthCode];
            }else{
                DLog(@"号码不满足");
            }
            return YES;
        }
    }else if (textField == _myAuthCodeTextField)
    {
        if (range.location == 4) {
            return NO;
        }else
        {
            if (![string isEqualToString:@""]) {
                checkString=[self.myAuthCodeTextField.text stringByAppendingString:string];
                
                DLog(@"checkString = %@",checkString);
                
            }else{
                checkString=[checkString stringByDeletingLastPathComponent];
            }
            
            if (![self.authCode isEqualToString:checkString]) {
                //验证码输入错误
                DLog(@"验证码输入错误");
                if (range.location == 3) {
                    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"验证码输入错误,请重新输入" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                    alert.tag = 101;
                    [alert show];
                }
            }else
            {
                [_getSMSButton setEnabled:YES];
            }
            return YES;
        }
    }else if(textField == _passwordTextField)
    {
        if (range.location == 15) {
            return NO;
        }else{
            if (![string isEqualToString:@""]) {
                checkString=[self.passwordTextField.text stringByAppendingString:string];
            }else{
                checkString=[checkString stringByDeletingLastPathComponent];
            }
            
            if ([self isPassword:checkString]) {
                DLog(@"密码满足要求");
                //再次发送请求，获取验证码
//                [[LoginManager getInstance]getAuthCode];
            }else{
                DLog(@"密码不满足要求");
                
            }
            return YES;
        }
    }else if(textField == _comfirmPasswordTextField)
    {
        if (range.location == 15) {
            return NO;
        }else{
            if (![string isEqualToString:@""]) {
                checkString=[self.passwordTextField.text stringByAppendingString:string];
            }else{
                checkString=[checkString stringByDeletingLastPathComponent];
            }
            
            return YES;
        }
    }
    
    return YES;
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101) {
        self.myAuthCodeTextField.text = @"";
        [self.myAuthCodeTextField resignFirstResponder];
    }else if (alertView.tag == 201)
    {
        self.phonenumTextField.text = @"";
        [self.phonenumTextField resignFirstResponder];
    }else if (alertView.tag == 301)
    {
        self.myAuthCodeTextField.text = @"";
        [self.myAuthCodeTextField resignFirstResponder];
    }else if (alertView.tag == 401)
    {
        self.passwordTextField.text = @"";
        [self.passwordTextField resignFirstResponder];
    }else if(alertView.tag == 501)
    {
        self.passwordTextField.text = @"";
        self.comfirmPasswordTextField.text = @"";
        [self.comfirmPasswordTextField resignFirstResponder];
    }else if (alertView.tag == 601)
    {
        User* u = [User getInstance];
        u.phoneNum = _phonenumTextField.text;
        
        [self.phonenumTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
        [self.phoneAuthCodeTextField resignFirstResponder];
        [self.comfirmPasswordTextField resignFirstResponder];
        [self.myAuthCodeTextField resignFirstResponder];
        
        [self.navigationController popViewControllerAnimated:YES];
    }else if (alertView.tag == 602)
    {
        //因为绑定手机号失败了 ，所以不做任何操作
    }
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)keyboardWasShown:(NSNotification *)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64.0, 0.0, kbSize.height, 0.0);
    self.tableView.scrollEnabled = YES;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    DLog(@"keyboardWasShown");
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.superview.superview.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, activeField.superview.superview.frame.origin.y-aRect.size.height+44);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
}
- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(64.0, 0, 0, 0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}


//点击return 按钮 去掉
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
//点击屏幕空白处去掉键盘
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.phonenumTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.phoneAuthCodeTextField resignFirstResponder];
    [self.comfirmPasswordTextField resignFirstResponder];
    [self.myAuthCodeTextField resignFirstResponder];
}

- (BOOL)isPassword:(NSString *)password
{
    NSString * regex = @"^[A-Za-z0-9]{6,15}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:password] == YES) {
        return YES;
    }else
    {
        return NO;
    }
}

- (BOOL)isMobileNumber:(NSString *)mobileNum
{
    NSString * MOBILE = @"^((13[0-9])|(14[^4,\\D])|(15[^4,\\D])|(18[0-9]))\\d{8}$|^1(7[0-9])\\d{8}$";
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    if ([regextestmobile evaluateWithObject:mobileNum] == YES){
        return YES;
    }else{
        return NO;
    }
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 1) {
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 15, 0, 0);
        // 三个方法并用，实现自定义分割线效果
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = insets;
        }
        
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:insets];
        }
        
        if([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]){
            [cell setPreservesSuperviewLayoutMargins:NO];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0;
    }
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

- (void)daojishi
{
    _daojishiTime += 1;
    
    _getSMSLabel.text = [NSString stringWithFormat:@"%d秒后重新获取", 60-_daojishiTime] ;
    
    if (_daojishiTime == 60) {
        _daojishiTime = 0;
        [_jishiTimer invalidate];
        _getSMSButton.hidden = NO;
        _getSMSLabel.hidden = YES;
    }
}

- (IBAction)getSMSAuthCode:(id)sender {
    //先判定验证码是否输入正确
    if ([self.authCodeLabel.text isEqualToString:self.myAuthCodeTextField.text]) {
        //验证码输入正确
        
        //向服务器发送请求，请求短信验证码
        [[LoginManager getInstance]requestSmsAuthCodeWithPhoneNum:self.phonenumTextField.text IpAddress:[CommonMethods deviceIPAdress]];
        
        //写一个计时器，1分钟后重新获取
        _getSMSButton.hidden = YES;
        _getSMSLabel.hidden = NO;
        _jishiTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(daojishi) userInfo:nil repeats:YES];
    }else
    {
        //验证码输入错误
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"验证码错误" message:@"很抱歉，验证码输入错误,请重新输入" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (IBAction)signUpConfirm:(id)sender {
    
    //判断是否输入正确了
    //先判断手机号
    if (![self isMobileNumber:self.phonenumTextField.text]) {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"手机号输入错误,请重新输入" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alert.tag = 201;
        [alert show];
    }else if (![self.myAuthCodeTextField.text isEqualToString:self.authCode])  //判断验证码
    {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"验证码输入错误,请重新输入" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alert.tag = 301;
        [alert show];
    }else if (![self isPassword:self.passwordTextField.text]) //判断密码
    {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"密码输入不满足要求,请重新输入" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alert.tag = 401;
        [alert show];
    }else if (![self.passwordTextField.text isEqualToString:self.comfirmPasswordTextField.text])
    {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"错误" message:@"两次密码输入不一致,请重新输入" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        alert.tag = 501;
        [alert show];
    }else
    {
        [[LoginManager getInstance]signUpPhoneNum:self.phonenumTextField.text osVersion:[NSString stringWithFormat:@"%f",[CommonMethods getIOSVersion]] password:self.comfirmPasswordTextField.text ip:[CommonMethods deviceIPAdress] city:self.cityName Smscode:self.phoneAuthCodeTextField.text];
    }
    
    
}
@end
