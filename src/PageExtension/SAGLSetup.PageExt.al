pageextension 55102 SAGLSetup extends "General Ledger Setup"
{
    layout
    {
        addlast(General)
        {
            field("SA Chase Check No. Series"; Rec."SA Chase Check No. Series")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specify the No. Series to be used for Chase Checks. This No. Series will generate the check numbers when creating the Chase Check file, since physical checks are not printed using the standard Print Check process.';
            }
        }
    }

}