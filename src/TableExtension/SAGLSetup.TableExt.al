tableextension 55101 SAGLSetup extends "General Ledger Setup"
{
    fields
    {
        field(55101; "SA Chase Check No. Series"; Code[20])
        {
            Caption = 'Chase Check No. Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series".Code;
        }
    }

}