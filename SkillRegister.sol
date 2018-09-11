pragma solidity ^0.4.20;

contract WorkbenchBase {
    event WorkbenchContractCreated(string applicationName, string workflowName, address originatingAddress);
    event WorkbenchContractUpdated(string applicationName, string workflowName, string action, address originatingAddress);

    string internal ApplicationName;
    string internal WorkflowName;

    function WorkbenchBase(string applicationName, string workflowName) internal {
        ApplicationName = applicationName;
        WorkflowName = workflowName;
    }

    function ContractCreated() internal {
        WorkbenchContractCreated(ApplicationName, WorkflowName, msg.sender);
    }

    function ContractUpdated(string action) internal {
        WorkbenchContractUpdated(ApplicationName, WorkflowName, action, msg.sender);
    }
}

contract SkillRegister is WorkbenchBase('SkillRegister', 'SkillRegister')
{
    enum StateType { Active, OfferPlaced, PendingInspection, Inspected, Appraised, NotionalAcceptance, BuyerAccepted, SellerAccepted, Accepted, Terminated }
    address public CertifiedProfessional;
    string public SkillName;
    uint public AskingSalary;
    string public CertificateURL;
    string public Institution;
    string public SkillDate;
    string public SkillExpiryDate;
    StateType public State;

    address public Employer;
    uint public OfferSalary;
    address public SkillInspector;
    address public SkillAppraiser;

    function SkillRegister(string skillName, uint256 salary, string certificateURL, string skillDate,string public skillExpiryDate, string institution  ) public
    {
        CertifiedProfessional = msg.sender;
        AskingSalary = salary;
        SkillName = skillName;
        State = StateType.Active;
        Institution = institution;
        SkillDate = skillDate;
        CertificateURL = certificateURL;

        
        ContractCreated();
    }

    function Terminate() public
    {
        if (CertifiedProfessional != msg.sender)
        {
            revert();
        }

        State = StateType.Terminated;
        ContractUpdated('Terminate');
    }

    function Modify(string SkillName, uint256 Salary) public
    {
        if (State != StateType.Active)
        {
            revert();
        }
        if (CertifiedProfessional != msg.sender)
        {
            revert();
        }

        SkillName = SkillName;
        AskingSalary = Salary;
        ContractUpdated('Modify');
    }

    function MakeOffer(address inspector, address appraiser, string skillName) public
    {
        if (inspector == 0x0 || appraiser == 0x0 || offerSalary == 0)
        {
            revert();
        }
        if (State != StateType.Active)
        {
            revert();
        }
        // Cannot enforce "AllowedRoles":["Buyer"] because Role information is unavailable
        if (CertifiedProfessional == msg.sender) // not expressible in the current specification language
        {
            revert();
        }

        Employer = msg.sender;
        SkillInspector = inspector;
        SkillAppraiser = appraiser;
        OfferSalary = FindMarketValue(skillName);
        State = StateType.OfferPlaced;
        ContractUpdated('MakeOffer');
    }

    function AcceptOffer() public
    {
        if (State != StateType.OfferPlaced)
        {
            revert();
        }
        if (CertifiedProfessional != msg.sender)
        {
            revert();
        }

        State = StateType.PendingInspection;
        ContractUpdated('AcceptOffer');
    }

    function Reject() public
    {
        if (State != StateType.OfferPlaced && State != StateType.PendingInspection && State != StateType.Inspected && State != StateType.Appraised && State != StateType.NotionalAcceptance && State != StateType.BuyerAccepted)
        {
            revert();
        }
        if (CertifiedProfessional != msg.sender)
        {
            revert();
        }

        Employer = 0x0;
        State = StateType.Active;
        ContractUpdated('Reject');
    }

    function Accept() public
    {
        if (msg.sender != Employer && msg.sender != CertifiedProfessional)
        {
            revert();
        }

        if (msg.sender == CertifiedProfessional &&
            State != StateType.NotionalAcceptance &&
            State != StateType.BuyerAccepted)
        {
            revert();
        }

        if (msg.sender == Employer &&
            State != StateType.NotionalAcceptance &&
            State != StateType.SellerAccepted)
        {
            revert();
        }

        if (msg.sender == Employer)
        {
            if (State == StateType.NotionalAcceptance)
            {
                State = StateType.BuyerAccepted;
            }
            else if (State == StateType.SellerAccepted)
            {
                State = StateType.Accepted;
            }
        }
        else
        {
            if (State == StateType.NotionalAcceptance)
            {
                State = StateType.SellerAccepted;
            }
            else if (State == StateType.BuyerAccepted)
            {
                State = StateType.Accepted;
            }
        }
        ContractUpdated('Accept');
    }

    function ModifyOffer(uint256 offerSalary) public
    {
        if (State != StateType.OfferPlaced)
        {
            revert();
        }
        if (Employer != msg.sender || offerSalary == 0)
        {
            revert();
        }

        OfferSalary = offerSalary;
        ContractUpdated('ModifyOffer');
    }

    function RescindOffer() public
    {
        if (State != StateType.OfferPlaced && State != StateType.PendingInspection && State != StateType.Inspected && State != StateType.Appraised && State != StateType.NotionalAcceptance && State != StateType.SellerAccepted)
        {
            revert();
        }
        if (Employer != msg.sender)
        {
            revert();
        }

        Employer = 0x0;
        OfferSalary = 0;
        State = StateType.Active;
        ContractUpdated('RescindOffer');
    }

    function MarkAppraised() public
    {
        if (SkillAppraiser != msg.sender)
        {
            revert();
        }

        if (State == StateType.PendingInspection)
        {
            State = StateType.Appraised;
        }
        else if (State == StateType.Inspected)
        {
            State = StateType.NotionalAcceptance;
        }
        else
        {
            revert();
        }
        ContractUpdated('MarkAppraised');
    }

    function FindMarketValue(string skillname) public  pure returns (uint256)
    {
        uint averageSalary;
        if (skillname == 'BigData'){
            averageSalary = 50000;
        }

        if (skillname == 'CloudArchitect'){
            averageSalary = 60000;
        }
        return averageSalary;
    }

     function IsValidCertificate(string certificateURL) public  pure returns (bool)
    {
        if (certificateURL.find("coursera".toSlice())){
           return true;
        else
            return false;
        }
    }



    function MarkInspected() public
    {
        if (SkillInspector != msg.sender)
        {
            revert();
        }

        if (State == StateType.PendingInspection)
        {
            bool result = IsValidCertificate(CertificateURL);
            State = StateType.Inspected;
        }
        else if (State == StateType.Appraised)
        {
            State = StateType.NotionalAcceptance;
        }
        else
        {
            revert();
        }
        ContractUpdated('MarkInspected');
    }
}