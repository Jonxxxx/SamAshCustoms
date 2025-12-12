reportextension 55100 SAPurchOrder extends "Standard Purchase - Order"
{
    dataset
    {
        add("Purchase Line")
        {
            column(SABuyFromVendorNo; "Purchase Header"."Buy-from Vendor No.")
            { }
            column(SABuyFromVendorName; "Purchase Header"."Buy-from Vendor Name")
            { }
            column(SALocationCode; "Purchase Line"."Location Code")
            { }
            column(SABuyFrmVendName_PurchHeader_Lbl; "Purchase Header".FieldCaption("Buy-from Vendor Name"))
            { }
            column(SALocation_PurchLine_Lbl; "Purchase Line".FieldCaption("Location Code"))
            { }
        }
    }
}
