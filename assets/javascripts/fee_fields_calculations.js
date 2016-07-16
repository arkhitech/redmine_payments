  $( "#payment_transaction_fee_fee_amount" )
  .change(function () {
    var inputtxt = $("#payment_transaction_fee_fee_amount");  
    if( inputtxt.value.match(/^-?\d*(\.\d+)?$/))   
     {   
     var netAmount = $("#payment_net_Amount");
     var invoiceAmount = $("#invoice_payment_amount"); 
      var feePercentage = $("#payment_transaction_fee_fee_percentage"); 
     
        netAmount.value = (invoiceAmount.value - inputtxt.value).toFixed(2)
        feePercentage.value = ((inputtxt.value/invoiceAmount.value)*100).toFixed(2)
     }  
     else
     {    
     return false;  
     }     
});
  $( "#payment_net_Amount" ).change(function () {
    var inputtxt = $("#payment_net_Amount");  
    if( inputtxt.value.match(/^-?\d*(\.\d+)?$/))   
     {   
     var FeeAmount = $("#payment_transaction_fee_fee_amount");
     var invoiceAmount = $("#invoice_payment_amount"); 
      var feePercentage = $("#payment_transaction_fee_fee_percentage"); 
        FeeAmount.value = (invoiceAmount.value - inputtxt.value).toFixed(2)
        feePercentage.value = ((FeeAmount.value/invoiceAmount.value)*100).toFixed(2)
     }  
     else
     {    
     return false;  
     }     
});
$( "#payment_transaction_fee_fee_percentage" )
  .change(function () {
    var inputtxt = $("#payment_transaction_fee_fee_percentage");  
    if( inputtxt.value.match(/^-?\d*(\.\d+)?$/))   
     {   
     var FeeAmount = $("#payment_transaction_fee_fee_amount");
     var invoiceAmount = $("#invoice_payment_amount"); 
      var netAmount = $("#payment_net_Amount"); 
        FeeAmount.value = ((inputtxt.value/100)*invoiceAmount.value).toFixed(2)
        netAmount.value = (invoiceAmount.value - FeeAmount.value).toFixed(2)
     }  
     else
     {    
     return false;  
     }     
});