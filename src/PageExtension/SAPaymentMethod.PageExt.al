pageextension 55100 SAPaymentMethod extends "Payment Methods"
{
    layout
    {
        addlast(Control1)
        {
            field(SAChaseCheckFormat; Rec.SAChaseCheckFormat)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify whether this payment method requires generating the Chase Check file before posting the payment journal.';
            }
        }

    }
}