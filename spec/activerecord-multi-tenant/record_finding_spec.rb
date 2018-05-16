require 'spec_helper'

describe MultiTenant, 'Record finding' do
  it 'searches for tenant object using the scope' do
    account = Account.create! name: 'test'
    project = account.projects.create! name: 'something'
    MultiTenant.with(account) do
      expect(Project.find(project.id)).to be_present
    end
  end

  it 'supports UUIDs' do
    organization = Organization.create! name: 'test'
    uuid_record = organization.uuid_records.create! description: 'something'
    MultiTenant.with(organization) do
      expect(UuidRecord.find(uuid_record.id)).to be_present
    end
  end

  it 'can use find_bys accurately' do
    first_tenant = Account.create! name: 'First Tenant'
    second_tenant = Account.create! name: 'Second Tenant'
    first_record = first_tenant.projects.create! name: 'identical name'
    second_record = second_tenant.projects.create! name: 'identical name'
    MultiTenant.with(first_tenant) do
      found_record = Project.find_by(name: 'identical name')
      expect(found_record).to eq(first_record)
    end
    MultiTenant.with(second_tenant) do
      found_record = Project.find_by(name: 'identical name')
      expect(found_record).to eq(second_record)
    end
  end

  it 'can scope records through associations even without the MultiTenant.with' do
    first_tenant = Account.create! name: 'First Tenant'
    second_tenant = Account.create! name: 'Second Tenant'
    identical_project_id = 145
    identical_task_id = 450

    first_record = first_tenant.projects.create! name: 'a', id: identical_project_id
    first_association = MultiTenant.with(first_tenant) do
      first_record.tasks.create! name: 'a', id: identical_task_id
    end

    second_record = second_tenant.projects.create! name: 'b', id: identical_project_id
    second_association = MultiTenant.with(second_tenant) do
      second_record.tasks.create! name: 'b', id: identical_task_id
    end

    expect(first_record.id).to eq second_record.id
    expect(first_association.id).to eq second_association.id

    different_record = second_tenant.projects.create! name: 'c'
    different_association = MultiTenant.with(second_tenant) do
      different_record.tasks.create! name: 'c'
    end

    found_through_different = second_tenant.projects.find_by(name: 'c').tasks
    expect(found_through_different.first).to eq different_association

    associated_to_first = first_tenant.projects
    expect(associated_to_first.length).to eq 1
    expect(associated_to_first.find_by(name: 'a')).to eq first_record

    associated_to_second = second_tenant.projects
    expect(associated_to_second.length).to eq 2
    expect(associated_to_second.find_by(name: 'b')).to eq second_record

    found_through_first = first_tenant.projects.find_by(name: 'a').tasks
    expect(found_through_first.length).to eq 1
    expect(found_through_first.first).to eq first_association

    found_through_second = second_tenant.projects.find_by(name: 'b').tasks
    expect(found_through_second.length).to eq 1
    expect(found_through_second.first).to eq second_association
  end
end
