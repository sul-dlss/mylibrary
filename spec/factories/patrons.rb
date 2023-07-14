# frozen_string_literal: true

FactoryBot.define do
  factory :sponsor_patron, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      { 'user' =>
        { 'username' => 'Sponsor1',
          'barcode' => 'Sponsor1',
          'active' => true,
          'personal' =>
          { 'email' => 'dlss-access-team@lists.stanford.edu',
            'lastName' => 'Sponsor',
            'firstName' => 'Shea',
            'preferredFirstName' => nil },
          'proxiesFor' => [],
          'proxiesOf' =>
          [{ 'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'proxyUser' => { 'barcode' => 'Proxy1',
                              'personal' => { 'firstName' => 'Piper', 'lastName' => 'Proxy' } } },
           { 'proxyUserId' => '8e03792c-e673-43c2-a412-a3796d7c8f7e',
             'proxyUser' => { 'barcode' => 'grad1',
                              'personal' => { 'firstName' => 'Gene', 'lastName' => 'Graduate' } } }],
          'expirationDate' => nil,
          'externalSystemId' => nil,
          'patronGroup' =>
          { 'desc' => 'Faculty Member',
            'group' => 'faculty',
            'limits' =>
            [{ 'conditionId' => 'e5b45031-a202-4abb-917b-e1df9346fe2c',
               'id' => 'eb2fd828-c113-45c7-862d-856cd83ec3e6',
               'patronGroupId' => '503a81cd-6c26-400f-b620-14c08943697c',
               'value' => 2,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' =>
                 'You have recalled library materials that must be returned. Your account is blocked.',
                 'name' => 'Maximum number of overdue recalls',
                 'valueType' => 'Integer' } },
             { 'conditionId' => 'cf7a0d5f-a327-4ca1-aa9e-dc55ec006b8a',
               'id' => '24054288-d929-4271-bcf0-fabb5add53fb',
               'patronGroupId' => '503a81cd-6c26-400f-b620-14c08943697c',
               'value' => 300,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => true,
                 'blockRequests' => false,
                 'message' => 'You have fees and fines to pay. Your account is blocked.',
                 'name' => 'Maximum outstanding fee/fine balance',
                 'valueType' => 'Double' } },
             { 'conditionId' => '08530ac4-07f2-48e6-9dda-a97bc2bf7053',
               'id' => '7b9cb6a8-d8fb-4c68-9166-67a369c50245',
               'patronGroupId' => '503a81cd-6c26-400f-b620-14c08943697c',
               'value' => 7,
               'condition' =>
               { 'blockBorrowing' => false,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' => '',
                 'name' => 'Recall overdue by maximum number of days',
                 'valueType' => 'Integer' } }] },
          'blocks' => [],
          'manualBlocks' => [] },
        'id' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
        'holds' =>
        [{ 'requestDate' => '2023-06-16T17:56:23.000+00:00',
           'item' =>
           { 'instanceId' => '4cd4ba91-394f-5efc-b867-75583a284583',
             'title' =>
             'A history of Persia',
             'itemId' => '250cdadc-189b-5658-b2a9-c7d2fc31ab9b',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'DS 3298 W3 42023 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'DS298 .W3 2023' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
             'author' => 'Watson, Robert Grant',
             'instance' => { 'hrid' => 'a14439363' },
             'isbn' => nil },
           'requestId' => '7fa87cfe-df57-4dc7-953b-a5a44ff37d91',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => nil,
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => '4827ae1d-b8bf-4b90-9e09-d642557893ab',
           'pickupLocation' => { 'code' => 'EARTH-SCI' },
           'queueTotalLength' => 4,
           'queuePosition' => 3,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil },
         { 'requestDate' => '2023-07-06T18:57:15.000+00:00',
           'item' =>
           { 'instanceId' => '99796220-1d4c-569f-bcf4-2bbe983b204f',
             'title' =>
             'Fiction!',
             'itemId' => 'e2271e84-896c-51e4-bc92-202eab13d0cd',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'PS 3129 T6 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'PS129 .T6' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
             'author' => 'Tooker, Dan; Hofheins, Roger',
             'instance' => { 'hrid' => 'a910877' },
             'isbn' => nil },
           'requestId' => '572919e2-0817-49df-87bc-04c9775ae48d',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => '2023-07-27T06:59:59.000+00:00',
           'details' =>
           { 'holdShelfExpirationDate' => nil,
             'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'proxy' => { 'firstName' => 'Piper', 'lastName' => 'Proxy', 'barcode' => 'Proxy1' } },
           'pickupLocationId' => '4827ae1d-b8bf-4b90-9e09-d642557893ab',
           'pickupLocation' => { 'code' => 'EARTH-SCI' },
           'queueTotalLength' => 1,
           'queuePosition' => 1,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => 'testing a proxy hold' }],
        'accounts' => [],
        'loans' =>
        [{ 'id' => 'f4817e08-7118-44e1-a5ab-40fc30b29ff7',
           'item' =>
           { 'title' =>
             'Music, sound, language, theater',
             'author' => 'Crown Point Press (Oakland, Calif.)',
             'instanceId' => '7f3c7afd-4bfa-5166-a883-7016cbae016d',
             'itemId' => '30d507db-6ac5-5574-b83c-665bd1573c07',
             'isbn' => nil,
             'instance' =>
             { 'indexTitle' =>
               'Music, sound, language, theater' },
             'item' =>
             { 'barcode' => '36105020835901',
               'id' => '30d507db-6ac5-5574-b83c-665bd1573c07',
               'status' => { 'date' => '2023-06-03T06:08:56.901+00:00', 'name' => 'Checked out' },
               'effectiveShelvingOrder' => 'N 46494 C63 M87 41980 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'N6494 .C63 M87 1980' },
               'effectiveLocation' => { 'code' => 'ART-STACKS', 'library' => { 'code' => 'ART' } },
               'permanentLocation' => { 'code' => 'ART-STACKS' } } },
           'loanDate' => '2023-06-03T06:08:45.521+00:00',
           'dueDate' => '2023-09-27T06:59:59.000+00:00',
           'overdue' => false,
           'details' =>
           { 'renewalCount' => nil,
             'dueDateChangedByRecall' => nil,
             'dueDateChangedByHold' => nil,
             'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
             'status' => { 'name' => 'Open' },
             'loanPolicy' =>
             { 'name' => '1qtr-3renew-7daygrace',
               'description' => 'Loan policy for monos owned by SUL, GSB and Law loaned to grad students',
               'renewable' => true,
               'renewalsPolicy' =>
               { 'alternateFixedDueDateSchedule' => nil,
                 'numberAllowed' => 3,
                 'period' => nil,
                 'renewFromId' => nil,
                 'unlimited' => false },
               'loansPolicy' =>
               { 'fixedDueDateSchedule' =>
                 { 'schedules' =>
                   [{ 'due' => '2023-04-04T06:59:59.000+00:00',
                      'from' => '1993-02-01T08:00:00.000+00:00',
                      'to' => '2023-02-25T07:59:59.000+00:00' },
                    { 'due' => '2023-06-27T06:59:59.000+00:00',
                      'from' => '2023-02-25T08:00:00.000+00:00',
                      'to' => '2023-05-13T06:59:59.000+00:00' },
                    { 'due' => '2023-09-27T06:59:59.000+00:00',
                      'from' => '2023-05-13T07:00:00.000+00:00',
                      'to' => '2023-08-15T06:59:59.000+00:00' }] },
                 'period' => nil } } } },
         { 'id' => 'e8d0dd5c-2b69-420f-bd91-075eebbe8eba',
           'item' =>
           { 'title' =>
             'See this sound',
             'author' => 'Daniels, Dieter; Naumann, Sandra; Thoben, Jan',
             'instanceId' => 'abdb8f6a-d3c3-5f7e-921c-0cfc4835f3bc',
             'itemId' => '95acc0f1-d699-5723-a89b-3329279a05d5',
             'isbn' => nil,
             'instance' => { 'indexTitle' => 'See this sound : audiovisuology : a reader' },
             'item' =>
             { 'barcode' => '36105224828744',
               'id' => '95acc0f1-d699-5723-a89b-3329279a05d5',
               'status' => { 'date' => '2023-06-03T06:09:34.414+00:00', 'name' => 'Checked out' },
               'effectiveShelvingOrder' => 'N 46494 M78 S44 42015 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'N6494 .M78 S44 2015' },
               'effectiveLocation' => { 'code' => 'ART-STACKS', 'library' => { 'code' => 'ART' } },
               'permanentLocation' => { 'code' => 'ART-STACKS' } } },
           'loanDate' => '2023-06-03T06:09:20.956+00:00',
           'dueDate' => '2023-09-27T06:59:59.000+00:00',
           'overdue' => false,
           'details' =>
           { 'renewalCount' => nil,
             'dueDateChangedByRecall' => nil,
             'dueDateChangedByHold' => nil,
             'proxyUserId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
             'status' => { 'name' => 'Open' },
             'loanPolicy' =>
             { 'name' => '1qtr-3renew-7daygrace',
               'description' => 'Loan policy for monos owned by SUL, GSB and Law loaned to grad students',
               'renewable' => true,
               'renewalsPolicy' =>
               { 'alternateFixedDueDateSchedule' => nil,
                 'numberAllowed' => 3,
                 'period' => nil,
                 'renewFromId' => nil,
                 'unlimited' => false },
               'loansPolicy' =>
               { 'fixedDueDateSchedule' =>
                 { 'schedules' =>
                   [{ 'due' => '2023-04-04T06:59:59.000+00:00',
                      'from' => '1993-02-01T08:00:00.000+00:00',
                      'to' => '2023-02-25T07:59:59.000+00:00' },
                    { 'due' => '2023-06-27T06:59:59.000+00:00',
                      'from' => '2023-02-25T08:00:00.000+00:00',
                      'to' => '2023-05-13T06:59:59.000+00:00' },
                    { 'due' => '2023-09-27T06:59:59.000+00:00',
                      'from' => '2023-05-13T07:00:00.000+00:00',
                      'to' => '2023-08-15T06:59:59.000+00:00' }] },
                 'period' => nil } } } },
         { 'id' => '75d92250-2188-4b73-b2e5-aefae6d5e17f',
           'item' =>
           { 'title' =>
             'Blue-collar Broadway',
             'author' => 'White, Timothy R., 1976-',
             'instanceId' => 'fb3a04f7-04a3-5ffa-a383-f49a735e4e37',
             'itemId' => '3eb63eec-9ce5-5cf0-9d6e-2c6f16137aa3',
             'isbn' => nil,
             'instance' =>
             { 'indexTitle' => 'Blue-collar broadway : the craft and industry of american theater' },
             'item' =>
             { 'barcode' => '36105212981729',
               'id' => '3eb63eec-9ce5-5cf0-9d6e-2c6f16137aa3',
               'status' => { 'date' => '2023-06-03T06:10:58.000+00:00', 'name' => 'Checked out' },
               'effectiveShelvingOrder' => 'PN 42277 N7 W48 42015 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'PN2277 .N7 W48 2015' },
               'effectiveLocation' => { 'code' => 'GRE-STACKS', 'library' => { 'code' => 'GREEN' } },
               'permanentLocation' => { 'code' => 'GRE-STACKS' } } },
           'loanDate' => '2023-06-03T06:10:52.704+00:00',
           'dueDate' => '2024-07-02T06:59:59.000+00:00',
           'overdue' => false,
           'details' =>
           { 'renewalCount' => nil,
             'dueDateChangedByRecall' => nil,
             'dueDateChangedByHold' => nil,
             'proxyUserId' => nil,
             'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1',
             'status' => { 'name' => 'Open' },
             'loanPolicy' =>
             { 'name' => '1yearfixed-2renew-7daygrace',
               'description' => 'Loan policy for monographs owned by SUL, GSB and Law loaned to faculty.',
               'renewable' => true,
               'renewalsPolicy' =>
               { 'alternateFixedDueDateSchedule' => nil,
                 'numberAllowed' => 2,
                 'period' => nil,
                 'renewFromId' => nil,
                 'unlimited' => false },
               'loansPolicy' =>
               { 'fixedDueDateSchedule' =>
                 { 'schedules' =>
                   [{ 'due' => '2023-07-01T06:59:59.000+00:00',
                      'from' => '1993-02-01T08:00:00.000+00:00',
                      'to' => '2023-05-01T06:59:59.000+00:00' },
                    { 'due' => '2024-07-02T06:59:59.000+00:00',
                      'from' => '2023-05-01T07:00:00.000+00:00',
                      'to' => '2024-05-01T06:59:59.000+00:00' }] },
                 'period' => nil } } } }],
        'totalCharges' => { 'isoCurrencyCode' => 'USD', 'amount' => 0 },
        'totalChargesCount' => 0,
        'totalLoans' => 3,
        'totalHolds' => 2 }.merge(custom_properties)
    end

    initialize_with { new(patron_info) }
  end

  factory :proxy_patron, class: 'Folio::Patron' do
    transient do
      custom_properties { {} } # Properties you can override in the test cases
    end

    patron_info do
      { 'user' =>
        { 'username' => 'Proxy1',
          'barcode' => 'Proxy1',
          'active' => true,
          'personal' =>
          { 'email' => 'dlss-access-team@stanford.edu',
            'lastName' => 'Proxy',
            'firstName' => 'Piper',
            'preferredFirstName' => nil },
          'proxiesFor' => [{ 'userId' => 'ec52d62d-9f0e-4ea5-856f-a1accb0121d1' }],
          'proxiesOf' => [],
          'expirationDate' => nil,
          'externalSystemId' => nil,
          'patronGroup' =>
          { 'desc' => 'Graduate Student',
            'group' => 'graduate',
            'limits' =>
            [{ 'conditionId' => 'cf7a0d5f-a327-4ca1-aa9e-dc55ec006b8a',
               'id' => '3cf0f601-2cab-470e-b4a9-2f7459943686',
               'patronGroupId' => 'ad0bc554-d5bc-463c-85d1-5562127ae91b',
               'value' => 50,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => true,
                 'blockRequests' => false,
                 'message' => 'You have fees and fines to pay. Your account is blocked.',
                 'name' => 'Maximum outstanding fee/fine balance',
                 'valueType' => 'Double' } },
             { 'conditionId' => 'e5b45031-a202-4abb-917b-e1df9346fe2c',
               'id' => '862cc936-21ea-442a-9763-1c6f5989c11d',
               'patronGroupId' => 'ad0bc554-d5bc-463c-85d1-5562127ae91b',
               'value' => 2,
               'condition' =>
               { 'blockBorrowing' => true,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' =>
                 'You have recalled library materials that must be returned. Your account is blocked.',
                 'name' => 'Maximum number of overdue recalls',
                 'valueType' => 'Integer' } },
             { 'conditionId' => '08530ac4-07f2-48e6-9dda-a97bc2bf7053',
               'id' => '830209d4-2110-4c1c-b943-0f8467884fe9',
               'patronGroupId' => 'ad0bc554-d5bc-463c-85d1-5562127ae91b',
               'value' => 7,
               'condition' =>
               { 'blockBorrowing' => false,
                 'blockRenewals' => false,
                 'blockRequests' => false,
                 'message' => '',
                 'name' => 'Recall overdue by maximum number of days',
                 'valueType' => 'Integer' } }] },
          'blocks' => [],
          'manualBlocks' => [] },
        'id' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
        'holds' =>
        [{ 'requestDate' => '2023-06-16T19:00:24.000+00:00',
           'item' =>
           { 'instanceId' => '4cd4ba91-394f-5efc-b867-75583a284583',
             'title' =>
             'A history of Persia',
             'itemId' => '250cdadc-189b-5658-b2a9-c7d2fc31ab9b',
             'item' =>
             { 'circulationNotes' => [],
               'effectiveShelvingOrder' => 'DS 3298 W3 42023 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'DS298 .W3 2023' },
               'effectiveLocation' => { 'code' => 'SAL3-STACKS', 'library' => { 'code' => 'SAL3' } } },
             'author' => 'Watson, Robert Grant',
             'instance' => { 'hrid' => 'a14439363' },
             'isbn' => nil },
           'requestId' => '5ae2588d-3c8e-49bd-9295-f2dedc336ae4',
           'status' => 'Open___Not_yet_filled',
           'expirationDate' => nil,
           'details' => { 'holdShelfExpirationDate' => nil, 'proxyUserId' => nil, 'proxy' => nil },
           'pickupLocationId' => '4d77d74b-271e-421a-91c6-992afa9afb3c',
           'pickupLocation' => { 'code' => 'MUSIC' },
           'queueTotalLength' => 4,
           'queuePosition' => 6,
           'cancellationReasonId' => nil,
           'canceledByUserId' => nil,
           'cancellationAdditionalInformation' => nil,
           'canceledDate' => nil,
           'patronComments' => nil }],
        'accounts' => [],
        'loans' =>
        [{ 'id' => '242c2dc3-6db5-40a1-a3ce-e1f27da86590',
           'item' =>
           { 'title' => 'Sci-fi architecture.',
             'author' => 'Toy, Maggie',
             'instanceId' => 'dbab2238-1a15-5ad8-af81-96805d798299',
             'itemId' => 'ac37b537-24a5-5fb7-8908-b798c1edb2e8',
             'isbn' => nil,
             'instance' => { 'indexTitle' => 'Sci-fi architecure.' },
             'item' =>
             { 'barcode' => '36105021987123',
               'id' => 'ac37b537-24a5-5fb7-8908-b798c1edb2e8',
               'status' => { 'date' => '2023-06-03T06:12:03.850+00:00', 'name' => 'Checked out' },
               'effectiveShelvingOrder' => 'NA 11 A16 V 269 NO 13 14 11',
               'effectiveCallNumberComponents' => { 'callNumber' => 'NA1 .A16' },
               'effectiveLocation' => { 'code' => 'ART-STACKS', 'library' => { 'code' => 'ART' } },
               'permanentLocation' => { 'code' => 'ART-STACKS' } } },
           'loanDate' => '2023-06-03T06:11:56.298+00:00',
           'dueDate' => '2023-09-27T06:59:59.000+00:00',
           'overdue' => false,
           'details' =>
           { 'renewalCount' => nil,
             'dueDateChangedByRecall' => nil,
             'dueDateChangedByHold' => nil,
             'proxyUserId' => nil,
             'userId' => 'bdfa62a1-758c-4389-ae81-8ddb37860f9b',
             'status' => { 'name' => 'Open' },
             'loanPolicy' =>
             { 'name' => '1qtr-3renew-7daygrace',
               'description' => 'Loan policy for monos owned by SUL, GSB and Law loaned to grad students',
               'renewable' => true,
               'renewalsPolicy' =>
               { 'alternateFixedDueDateSchedule' => nil,
                 'numberAllowed' => 3,
                 'period' => nil,
                 'renewFromId' => nil,
                 'unlimited' => false },
               'loansPolicy' =>
               { 'fixedDueDateSchedule' =>
                 { 'schedules' =>
                   [{ 'due' => '2023-04-04T06:59:59.000+00:00',
                      'from' => '1993-02-01T08:00:00.000+00:00',
                      'to' => '2023-02-25T07:59:59.000+00:00' },
                    { 'due' => '2023-06-27T06:59:59.000+00:00',
                      'from' => '2023-02-25T08:00:00.000+00:00',
                      'to' => '2023-05-13T06:59:59.000+00:00' },
                    { 'due' => '2023-09-27T06:59:59.000+00:00',
                      'from' => '2023-05-13T07:00:00.000+00:00',
                      'to' => '2023-08-15T06:59:59.000+00:00' }] },
                 'period' => nil } } } }],
        'totalCharges' => { 'isoCurrencyCode' => 'USD', 'amount' => 0 },
        'totalChargesCount' => 0,
        'totalLoans' => 1,
        'totalHolds' => 1 }.merge(custom_properties)
    end

    initialize_with { new(patron_info) }
  end
end
