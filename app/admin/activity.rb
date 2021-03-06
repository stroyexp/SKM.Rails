ActiveAdmin.register Activity do
  include AdminWebPage

  menu priority: 2

  permit_params :published, :navigated,
                :name, :header, :content,
                :title, :keywords, :description, :canonical, :robots,
                :index,
                :parent_id,
                :attaches_purge, attaches: [], attaches_attachments_attributes: [:id, :index, :_destroy],
                area_ids: []
=begin
                images_attributes: [:id, :index,
                                    :title, :description, :alt,
                                    :upload, :upload_crop,
                                    :_destroy]
=end

  includes :areas, :attaches_attachments # :images


  scope :all, default: true
  scope :unscoped


  sortable tree: true,
           max_levels: 2,
           sorting_attribute: :index
  # config.paginate = true

  filter :name
  filter :published
  filter :navigated
  filter :areas,
         input_html: {class: 'c-control-select'},
         unless: proc { Area.all.empty? }
  filter :created_at

  index default: true do
    selectable_column
    id_column
    column_aimg :attach, class: 'h-width--icon'
    column :published, class: 'h-size--bool'
    column :navigated, class: 'h-size--bool'
    column :name
    column :areas, class: 'h-size--20' do |model|
      model.areas_show '<br>'
    end
    column :created_at
    column :index, class: 'h-size--int'
    actions
  end

  index as: :sortable do
    label :name do |model|
      html = '%03i %s %s <i>[ %s ]</i> <span>%03i</span>' % [
        model.index,
        (model.published ? '<i>опубликовано</i>' : '<em>не опубликовано</em>'),
        (model.navigated ? '<i>в навигации</i>' : '<em>вне навигации</em>'),
        (model.areas.empty? ? '--' : model.areas_show),
        model.id
      ]
      html = "%s <small>%s</small>" % [model.name, html]
      html.html_safe
    end
    actions
  end


  show do
    attributes_table do
      row :published
      row :navigated
      row :areas do |model|
        model.areas_show '<br>'
      end
      row_html :header
      row :partial
      row_html :content, class: 'h-text--readable'
    end
    panel I18n.t('active_admin.panels.images', count: resource.attaches.count) do
      render partial: 'admin/show/images'
    end unless resource.attaches.empty?
    panel I18n.t('active_admin.panels.seo') do
      render partial: 'admin/show/seo'
    end
=begin
    panel 'Изображения' do
      table_for resource.images do
        column :id, class: 'h-size--integer' do |model|
          if can? :update, Image
            link_to model.id, edit_admin_image_path(model)
          else
            model.id
          end
        end
        column :upload, class: 'h-size--icon' do |model|
          imagic_tag model.upload.icon
        end
        column :title, class: 'h-size--40'
        column :alt
        column :upload_crop, class: 'h-size--10' do |model|
          status_tag model.upload_crop
        end
      end
    end unless resource.images.empty?
=end
    active_admin_comments
  end


  form do |f|
    f.semantic_errors *f.object.errors.keys
    tabs do
      tab 'Данные' do
        f.inputs do
          f.input :published, as: :select, include_blank: false,
                  input_html: {class: 'c-control-select'}
          f.input :navigated, as: :select, include_blank: false,
                  input_html: {class: 'c-control-select'}
          f.input :areas, as: :select, include_hidden: false, include_blank: false, multiple: true,
                  collection: Area.all.collect { |model| [model.name, model.id] },
                  input_html: {class: 'c-control-select c-control-select--full h-size--50',
                               size: Area.all.count} unless f.object.new_record? || Area.all.empty?
        end
=begin
        f.inputs do
          f.input :index, as: :number,
                  input_html: {class: 'h-size--10',
                               min: 0}
          f.input :parent_id, as: :select, include_blank: true,
                  collection: Activity.select_options,
                  input_html: {class: 'c-control-select'}
        end
=end
        f.inputs do
          f.input :name,
                  input_html: {class: 'h-size--40'}
          f.input :header
          f.input :partial, as: :select, include_blank: false,
                  input_html: {class: 'c-control-select'}
          f.input :content, as: :redactor
        end
      end
      tab I18n.t('active_admin.panels.images', count: f.object.attaches.count) do
        render partial: 'admin/form/images', locals: {form: f}
      end unless f.object.new_record?
      tab I18n.t('active_admin.panels.seo') do
        render partial: 'admin/form/seo', locals: {form: f}
      end
=begin
      tab 'Изображения' do
        f.inputs do
          f.has_many :images, heading: false, class: 'has-upload_icon',
                     sortable: 'index', allow_destroy: true, new_record: 'Добавить' do |n|
            if n.object.new_record?
              n.input :upload, as: :file,
                      input_html: {accept: n.object.upload.input_accept}
            else
              n.input :upload, as: :upload_icon,
                      wrapper_html: {class: 'handle'}
            end
            n.input :title
            n.input :alt
            n.object.upload_crop = true if n.object.new_record?
            n.input :upload_crop, as: :select, include_blank: false,
                    input_html: {class: 'c-control-select'}
          end
        end
      end unless f.object.new_record?
=end
    end
    f.actions
  end


  sidebar I18n.t('active_admin.sidebars.relations'),
          priority: 0, only: [:show, :edit, :update] do
    attributes_table do
      row :parent
      row :index
    end
  end

  sidebar I18n.t('active_admin.sidebars.state'),
          priority: 1, only: [:show, :edit, :update] do
    attributes_table_for resource do
      row :published
      row :navigated
      row :index
      row :id
      row :updated_at
      row :created_at
    end
  end

  sidebar I18n.t('activerecord.attributes.activity.attach'),
          priority: 2, only: [:show, :edit, :update] do
    render partial: 'admin/image', object: resource.attach,
           locals: {size: 192}
  end


  controller do
    def create
      super do |format|
        redirect_to edit_admin_activity_path(resource) and return if resource.valid?
      end
    end

    def update
      params[:activity][:area_ids] = [] unless params[:activity].include? :area_ids
      purge = []
      if params[:activity].include? :attaches_attachments_attributes
        params[:activity][:attaches_attachments_attributes].each do |idx, param|
          if param[:_destroy] == '1'
            purge << param[:id]
            param[:_destroy] = '0'
          end
        end
      end
      attaches = params[:activity].include?(:attaches) ? params[:activity].delete('attaches') : false
      super do |format|
        if resource.valid?
          if params[:activity][:attaches_purge] == '1'
            resource.attaches.purge
          elsif !purge.empty?
            ActiveStorage::Attachment.find(purge).each(&:purge)
          end
          if attaches
            resource.attaches.attach attaches
          end
          if !resource.attaches.empty? && (!purge.empty? || attaches)
            resource.attaches.order(:index).each.with_index do |item, idx|
              item.update_column :index, idx
            end
          end
        end
      end
    end
  end

=begin
  action_item :images_recreate_versions, only: :index do
    link_to 'Перемонтировать изображения',
            images_recreate_versions_admin_activities_path,
            method: :patch
  end

  action_item :images_recreate_versions, only: :show do
    link_to 'Перемонтировать изображения',
            images_recreate_versions_admin_activities_path(id: resource),
            method: :patch
  end


  collection_action :images_recreate_versions, method: :patch do
    if permitted_params[:id].blank?
      done = Activity.images_recreate_versions
      redirect_back fallback_location: admin_dashboard_path, notice: "[#{done}] Изображения коллекции перемонтированы!"
    else
      done = Activity.find(permitted_params[:id]).images_recreate_versions
      redirect_back fallback_location: admin_dashboard_path, notice: "[#{done}] Изображения модели перемонтированы!"
    end
  end
=end
end
