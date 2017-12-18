# frozen_string_literal: true

class ChangeVisitIdTypeOfAhoyEventsToInteger < ActiveRecord::Migration[5.0]
  def up
    drop_table "ahoy_events"
    create_table "ahoy_events", force: :cascade do |t|
      t.integer  "visit_id"
      t.integer  "user_id"
      t.string   "name"
      t.text     "properties"
      t.datetime "time"
      t.index ["time"], name: "index_ahoy_events_on_time"
      t.index ["user_id"], name: "index_ahoy_events_on_user_id"
      t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
    end
  end

  def down
    drop_table "ahoy_events"
    create_table "ahoy_events", force: :cascade do |t|
      t.uuid  "visit_id"
      t.integer  "user_id"
      t.string   "name"
      t.text     "properties"
      t.datetime "time"
      t.index ["time"], name: "index_ahoy_events_on_time"
      t.index ["user_id"], name: "index_ahoy_events_on_user_id"
      t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
    end
  end

end
