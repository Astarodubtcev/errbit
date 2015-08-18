require 'spec_helper'

describe 'Automatic issue creation' do
  let(:xml) { Rails.root.join('spec','fixtures','hoptoad_test_notice.xml').read }
  let(:issue_creation) { double 'issue creation' }
  let(:errbit_app) { Fabricate(:app, api_key: 'APIKEY', auto_issue_creation: true) }

  before { allow(IssueCreation).to receive(:new) { issue_creation } }
  before { allow(issue_creation).to receive(:execute) {} }

  context 'without issue link' do
    it "generates a notice from xml and creates issue" do
      expect(IssueCreation).to receive(:new).exactly(1).times

      expect {
        post '/notifier_api/v2/notices', :data => xml
        expect(response).to be_success
      }.to change {
        errbit_app.problems.count
      }.by(1)
    end
  end

  context 'with issue link' do
    let(:problem) { Fabricate(:problem, issue_link: 'link', error_class: 'HoptoadTestingException') }
    let(:error) { Fabricate(:err, problem: problem, fingerprint: 'd1a4bc4936c8479c52df8b01a51ffd426c4fcbc5') }

    before do
      problem.errs << error
      problem.save
    end

    before do
      errbit_app.problems << problem
      errbit_app.save
    end

    it "generates a notice from xml did not creates issue" do
      expect(IssueCreation).to receive(:new).exactly(0).times

      post '/notifier_api/v2/notices', :data => xml
      expect(response).to be_success
    end
  end
end
