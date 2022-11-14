# frozen_string_literal: true

# Migration responsible for creating a table with activities
class CreateAuditableEvents < ((ActiveRecord.version.release < Gem::Version.new("5.2.0")) ? ActiveRecord::Migration : ActiveRecord::Migration[5.2])
  # Create table
  def self.up
    create_table :auditable_events, id: :uuid, default: "gen_random_uuid()" do |t|
      t.belongs_to :trackable, polymorphic: true, type: :uuid
      t.belongs_to :owner, polymorphic: true, type: :uuid
      t.string :key
      t.text :parameters
      t.belongs_to :recipient, polymorphic: true, type: :uuid

      t.timestamps
    end

    add_index :auditable_events, [:trackable_id, :trackable_type]
    add_index :auditable_events, [:owner_id, :owner_type]
    add_index :auditable_events, [:recipient_id, :recipient_type]
  end

  # Drop table
  def self.down
    drop_table :auditable_events
  end
end
