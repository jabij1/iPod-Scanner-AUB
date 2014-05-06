--------------------------------------------------------------------------------------------------------
Warning: iOS6 versions prior to 6.1 (6.00 and 6.01) has severe issues with external accessory framework, that result in unstable communication, unable to connect until the device is
physically detached and reattached, EA thread leaks or whole program crashes. SDK 1.70+ mitigate the issue to a degree, but it still happens. Fixed in iOS6.1 beta 3 and up.

--------------------------------------------------------------------------------------------------------
Warning: Starting with 1.64 the library is compiled with XCode 4.5 (because of need of armv7s requirement in iPhone5). Also armv6 support is dropped.

--------------------------------------------------------------------------------------------------------
Universal SDK:
With 1.60 release of the library a new SDK was created, that aims to replace Printer,Linea and Pinpad SDKs and provide unified access to all device functions,
without the need of the calling program to know which device it is connected to, it can only care if required feature is present on the connected devie (barcode reader, magnetic stripe reader...).
Based on NSError functions from LineaSDK, it provides easy migration for current LineaSDK users, only few nonessential functions are removed, some are automated
(for example there is no need to maunally call msStart function anymore, or calling barcodeEnginePowerControl, the SDK does that automatically).
Universal SDK includes support for "features" - both with notification when features become available or unavailable, and via function to query manually for supported feature.
Features include barcode engine (type), magnetic stripe reader (type), bluetooth, battery charging, RF card reader module, printing, pin entry, etc. 
The Universal SDK can work with multiple devices at once by different communication protocols, for example while connected to Linea connect printer via bluetooth.
In this case "printing" feature will become available and print functions will be active.

Migrating from LineaSDK to UniversalSDK:
- change include file from LineaSDK.h to DTDevices.h
- make sure you are not using the very old NSException based linea functions, but rather NSError based ones, will get warnings (if not ARC) or errors (if ARC) in this case, check out migration guide to NSError below
- remove all instances of barcodeEnginePowerControl, this function is automatic now
- remove all instances of btSetEnabled/btGetEnabled, the bluetooth module power is controlled automatically when needed
- msStartScan is no longer needed, you can remove. However, the function is present in case you want to disable temporary magnetic card reading
- old synchronous discover of bluetooth devices functions are removed to enforce not blocking the main thread, can be implemented back if needed, but it is best the async ones are used
- if you have checked Linea model string for indication of some feature being present, like "CM" for encrypted head, then it is best to switch over to feature API, as it will work for devices other than Linea
If you have used PrinterSDK along with LineaSDK:
- remove all references to the PrinterSDK.h file, along with the instance variable, connect and disconnect code
- convert function names: usually the only addition is the prn prefix and the next letter being capital, i.e. printText becomes prnPrintText
- use btConnectSupportedDevice instead of btConnect to connect to the printer
- if you want to detect printing functions being available/unavailable use the feature api, by providing a delegate function (instead of prnConnectionState):

-(void)deviceFeatureSupported:(int)feature value:(int)value
{
...
    if(feature==FEAT_PRINTING)
    {
        if(value==FEAT_SUPPORTED)
        {
            [dtdev prnPrintText:@"{=C}{+B}PRINTER CONNECTED" error:nil];
            [dtdev prnFeedPaper:0 error:nil];
        }else
        {
            [self removeController:printViewController];
        }
    }
...
}


Migrating from NSException to NSError based functions:
As explained in the warning below, ARC made NSException based functions highly undesirable and plain dangerous to use, so NSError based equivalents were created, keeping them as close as possible to the originals
- uncomment //#define LINEA_NO_EXCEPTIONS line in LineaSDK.h file, this will disable all NSException based functions and XCode will give errors/warnings, easier to spot the places
- all functions return YES/NO or object/nil upon success/failure
- all functions got NSError ** parameter, which can be nil if you don't want the return information
- the NSError ** parameter is always put as last argument to the function
- some functions that previously returned simple types had to be changed with additional parameter, for example
(int)barcodeGetScanMode had to be changed to (BOOL)barcodeGetScanMode:(int *)mode error:(NSError **)error;
- all @try/@catch or NS_HANDLER/NS_ENDHANDLER should be removed


--------------------------------------------------------------------------------------------------------
Warning: XCode 4.2 release supports Automatic Reference Counting (ARC) feature, that greatly reduces the risk of memory
issues and streamlines the development. With ARC, however, the exception handling was changed to be unsafe by default -
that means, object allocated within @try @catch statements will leak upon raising exception. The bad news - the SDK relies
on exceptions and this means huge potential leaks when program is compiled with ARC. Thankfully, new compiler option
solves that, so if you want to use the library with ARC, then go to target settings and put -fobjc-arc-exceptions
in Other C flags line.
The other thing ARC did was to disallow object inside structures, and there are a couple of functions in Linea and Printer
SDKs that use that, they were replaced by NSDictionary versions, so if you are going to update to ARC, you have to switch
over to these new functions. Demo programs were updated to reflect that

--------------------------------------------------------------------------------------------------------
Warning: iOS 5.01 and later (including 5.1, fixed in iOS6) contain a bug, where after the iOS device is left connected with the Linea,
with program running for extended periods of time (10+ hours) without the iOS getting unlocked, it may refuse to connect
to Linea until the iOS is restarted or disconnected and reconnected to Linea. Apple are notified of the issue.
Possible workaround exists by making the program always connected to the accessory, even on background, by setting external-accessory in UIBackgroundModes:
http://developer.apple.com/library/ios/#documentation/general/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html
It does, however, have severe impact on the battery life on Linea with Opticon 2D engine when using barcodeEnginePowerControl:TRUE.
To combat that, new option to barcodeEnginePowerControl is added in (requires firmware 2.64) to specify maximum inactivity timeout,
after which the engine will be turned off. Setting it to a value, over the maximum, which device is expected to idle in the day,
like one hour, will ensure long battery life and going around the issue.