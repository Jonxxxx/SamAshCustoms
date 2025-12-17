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
            column(SABuyFrmVendName_PurchHeader_Lbl; VendorDescLbl)
            { }
            column(SALocation_PurchLine_Lbl; LocationLbl)
            { }
            column(SABuyFrmVendNo_PurchHeader_Lbl; VendorNoLbl)
            { }
        }
    }

    var
        VendorNoLbl: Label 'Vendor No.';
        VendorDescLbl: Label 'Vendor Description';
        LocationLbl: Label 'Location';
}
