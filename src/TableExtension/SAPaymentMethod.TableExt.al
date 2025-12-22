tableextension 55100 SAPaymentMethod extends "Payment Method"
{
    fields
    {
        field(55100; SAChaseCheckFormat; Boolean)
        {
            AllowInCustomizations = AsReadWrite;
            DataClassification = CustomerContent;
            Caption = 'Chase Check Format';
        }
    }

}