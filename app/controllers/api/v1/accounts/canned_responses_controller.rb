class Api::V1::Accounts::CannedResponsesController < Api::V1::Accounts::BaseController
  before_action :fetch_canned_response, only: [:update, :destroy]

  def index
    render json: canned_responses
  end

  def create
    @canned_response = Current.account.canned_responses.new(canned_response_params)

    if params[:canned_response][:canned_file].present?
      uploaded_file = params[:canned_response][:canned_file]
      # Lógica para guardar el archivo (ejemplo: guardar en el sistema de archivos local)
      begin
        # Asegúrate de que el directorio de destino exista
        FileUtils.mkdir_p(Rails.root.join('public', 'uploads', 'canned_responses')) unless Dir.exist?(Rails.root.join('public', 'uploads', 'canned_responses'))
        file_path = Rails.root.join('public', 'uploads', 'canned_responses', SecureRandom.hex + '-' + uploaded_file.original_filename)
        File.open(file_path, 'wb') do |file|
          file.write(uploaded_file.read)
        end
        @canned_response.file_path = '/uploads/canned_responses/' + File.basename(file_path) # Guarda la ruta relativa para acceder desde la web
      rescue => e
        render json: { errors: ["Error al guardar el archivo: #{e.message}"] }, status: :unprocessable_entity and return
      end
    end

    @canned_response.save!
    render json: @canned_response
  end

  def update
    if params[:canned_response][:canned_file].present?
      uploaded_file = params[:canned_response][:canned_file]

      # Eliminar el archivo antiguo si existía
      if @canned_response.file_path.present?
        file_to_delete = Rails.root.join('public', @canned_response.file_path)
        if File.exist?(file_to_delete)
          begin
            File.delete(file_to_delete)
            Rails.logger.info "Archivo antiguo eliminado exitosamente durante UPDATE: #{file_to_delete}"
          rescue => e
            Rails.logger.error "Error al eliminar archivo antiguo durante UPDATE: #{file_to_delete} - #{e.message}"
            # Considerar si quieres manejar el error de eliminación del archivo antiguo de forma diferente.
          end
        else
          Rails.logger.warn "Archivo antiguo no encontrado durante UPDATE: #{file_to_delete}"
        end
      end

      # Guardar el nuevo archivo (lógica similar a la de `create`)
      begin
        FileUtils.mkdir_p(Rails.root.join('public', 'uploads', 'canned_responses')) unless Dir.exist?(Rails.root.join('public', 'uploads', 'canned_responses'))
        file_path = Rails.root.join('public', 'uploads', 'canned_responses', SecureRandom.hex + '-' + uploaded_file.original_filename)
        File.open(file_path, 'wb') do |file|
          file.write(uploaded_file.read)
        end
        params[:canned_response][:file_path] = '/uploads/canned_responses/' + File.basename(file_path) # Actualiza los params para que se guarden en la DB
      rescue => e
        render json: { errors: ["Error al guardar el nuevo archivo durante UPDATE: #{e.message}"] }, status: :unprocessable_entity and return
      end
    end

    @canned_response.update!(canned_response_params)
    render json: @canned_response
 end

  def destroy
    if @canned_response.file_path.present?
      file_to_delete = Rails.root.join('public', @canned_response.file_path)
      if File.exist?(file_to_delete)
        begin
          File.delete(file_to_delete)
          Rails.logger.info "Archivo eliminado exitosamente: #{file_to_delete}" # Log informativo
        rescue => e
          Rails.logger.error "Error al eliminar el archivo: #{file_to_delete} - #{e.message}" # Log de error
          # Aunque falle la eliminación del archivo, NO vamos a abortar la eliminación de la canned response.
          # Podríamos considerar un mecanismo para reintentar la eliminación del archivo en background (ej. Sidekiq) si es crítico.
        end
      else
        Rails.logger.warn "Archivo no encontrado para eliminar: #{file_to_delete}" # Log de warning
      end
    end
    @canned_response.destroy!
    head :ok
 end

  private

  def fetch_canned_response
    @canned_response = Current.account.canned_responses.find(params[:id])
  end

  def canned_response_params
    params.require(:canned_response).permit(:short_code, :content, :file_path) # Permite el nuevo atributo file_path
  end

  def canned_responses
    if params[:search]
      Current.account.canned_responses
            .where('short_code ILIKE :search OR content ILIKE :search', search: "%#{params[:search]}%")
            .order_by_search(params[:search])
    else
      Current.account.canned_responses
    end
  end
end