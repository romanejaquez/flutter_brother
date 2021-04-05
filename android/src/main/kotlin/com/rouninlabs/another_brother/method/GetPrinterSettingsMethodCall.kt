package com.rouninlabs.another_brother.method

import android.content.Context
import android.graphics.BitmapFactory
import android.util.Log
import com.brother.ptouch.sdk.Printer
import com.brother.ptouch.sdk.PrinterInfo
import com.brother.ptouch.sdk.PrinterStatus
import com.rouninlabs.another_brother.BrotherManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

/**
 * Command for getting the printer settings a Brother printer.
 * This support both one-time as well as the standard openCommunication/print/closeCommunication
 * approach.
 */
class GetPrinterSettingsMethodCall(val context: Context, val call: MethodCall, val result: MethodChannel.Result) {
    companion object {
        const val METHOD_NAME = "getPrinterSettings"
    }

    fun execute() {

        GlobalScope.launch(Dispatchers.IO) {

            val dartPrintInfo: HashMap<String, Any> = call.argument<HashMap<String, Any>>("printInfo")!!
            val printerId: String = call.argument<String>("printerId")!!
            val dartKeys:List<Map<String, Any>> = call.argument("keys")!!

            // Decoded Printer Info
            val printInfo = printerInfofromMap(dartPrintInfo)

            // A print request is considered one-time if there was no printer tracked with this ID.
            // this will open a new connection and close it when done.
            // If it is not one-time it means someone must have already opened a connection using
            // the startCommunication() API. When endCommunication() is called that printer will be removed.
            // Create Printer
            val trackedPrinter = BrotherManager.getPrinter(printerId = printerId)
            val isOneTime:Boolean = trackedPrinter == null;
            val printer = trackedPrinter?: Printer()

            // Prepare local connection.
            val error = setupConnectionManagers(context = context, printer = printer, printInfo = printInfo)
            if (error != PrinterInfo.ErrorCode.ERROR_NONE) {
                // There was an error notify
                withContext(Dispatchers.Main) {
                    // Set result Printer status.
                    result.success(hashMapOf(
                            "printerStatus" to PrinterStatus().apply {
                                errorCode = error
                            }.toMap(),
                            "values" to hashMapOf<Map<String, Any>, Any>()
                    ))
                }
                return@launch
            }

            // Set Printer Info
            printer.printerInfo = printInfo

            // Start communication
            if (isOneTime) {
                // Note: Starting a communication does not seem to impact whether we can print or
                // not. Calling print without calling this seems to still print fine.
                val started: Boolean = printer.startCommunication()
            }

            val settingKeys = dartKeys.map { printerSettingItemFromMap(it) }
            val outValues:MutableMap<PrinterInfo.PrinterSettingItem, String> = hashMapOf()
            
            // Get settings
            val printResult = printer.getPrinterSettings(settingKeys, outValues);

            // End Communication
            if (isOneTime) {
                val connectionClosed: Boolean = printer.endCommunication()
            }
            // Encode PrinterStatus
            val dartPrintStatus = printResult.toMap()
            val dartOutValues:Map<Map<String, Any>, Any> = outValues.entries.associate { (key, value) -> key.toMap() to value }
           withContext(Dispatchers.Main) {
               // Set result Printer status.
               result.success(hashMapOf(
                   "printerStatus" to dartPrintStatus,
                   "values" to dartOutValues
               ))
           }
        }

    }
}