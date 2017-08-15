///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем	OAuth_Токен;
Перем	УдалитьИсточник;

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Отправить файл на Yandex-Диск");
	
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ПутьКФайлу", "Путь к файлу для отправки на Yandex-диск");
	
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
	"-ya-token",
	"Token авторизации");
	
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
	"-ya-path",
	"Путь к файлу на Yandex-Диск");
	
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, 
	"-delsource",
	"Удалить исходный файл после отправки");
	
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды,
	"-use-source-as-split",
	"Использовать исходный файл как список имен файлов для передачи");
	
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды,
	"-check-hash",
	"Проверять совпадение хешей скопированных файлов");
	
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры

Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
	
	ПутьКФайлу				= ПараметрыКоманды["ПутьКФайлу"];
	OAuth_Токен				= ПараметрыКоманды["-ya-token"];
	ЦелевойПуть				= ПараметрыКоманды["-ya-path"];
	УдалитьИсточник			= ПараметрыКоманды["-delsource"];
	ЭтоСписокФайлов			= ПараметрыКоманды["-use-source-as-split"];
	
	Если ЭтоСписокФайлов = Неопределено Тогда
		ЭтоСписокФайлов	= Ложь;
	Иначе
		ЭтоСписокФайлов = Истина;
	КонецЕсли;
	
	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();
	
	
	Если ПустаяСтрока(ПутьКФайлу) Тогда
		Лог.Ошибка("Не указан путь к файлу для помещения на Yandex-Диск");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;
	
	Если ПустаяСтрока(OAuth_Токен) Тогда
		Лог.Ошибка("Не задан Token авторизации");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

// Если целевой путь не указан - тогда используется корень Яндекс-диска
	Если ПустаяСтрока(ЦелевойПуть) Тогда
//		Лог.Ошибка("Не задан путь к целевому файлу на Yandex-Диск");
//		Возврат ВозможныйРезультат.НеверныеПараметры;
		ЦелевойПуть = "";
	КонецЕсли;
	
	МассивОтправляемыхФайлов = Новый Массив;
	ФайлИнфо = Новый Файл(ПутьКФайлу);
	ЯндексДиск = Неопределено;

	Если НЕ ЭтоСписокФайлов Тогда
		МассивОтправляемыхФайлов.Добавить(ПутьКФайлу);
	Иначе
		// Добавляем файл списка для закачки на Я-Диск
		МассивОтправляемыхФайлов.Добавить(ПутьКФайлу);

		// открываем и читаем построчно исходный файл
		ЧтениеСписка = Новый ЧтениеТекста(ПутьКФайлу, КодировкаТекста.UTF8);
		СтрокаСписка = ЧтениеСписка.ПрочитатьСтроку();
		Пока СтрокаСписка <> Неопределено Цикл
			Если ЗначениеЗаполнено(СокрЛП(СтрокаСписка)) Тогда
				МассивОтправляемыхФайлов.Добавить(СтрокаСписка);
			КонецЕсли;
			
			СтрокаСписка = ЧтениеСписка.ПрочитатьСтроку();
		КонецЦикла;
		ЧтениеСписка.Закрыть();
		// Определяем наличие каталога

		Если ЗначениеЗаполнено(ЦелевойПуть) Тогда
			СоздатьПапкуНаЯДиске(ЯндексДиск, ЦелевойПуть);
		КонецЕсли;
	КонецЕсли;
	
	Для Каждого ОтправляемыйФайл ИЗ МассивОтправляемыхФайлов Цикл
		
		РезультатОтправки = ОтправитьФайлНаЯДиск(ЯндексДиск, ФайлИнфо.Путь, ОтправляемыйФайл, ЦелевойПуть);
		Если НЕ РезультатОтправки Тогда
			Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
		КонецЕсли;
	КонецЦикла;
	
	Возврат ВозможныйРезультат.Успех;
КонецФункции

// Функция отправки файла на Я-Диск
Функция ОтправитьФайлНаЯДиск(ЯДиск = Неопределено, Знач Каталог, Знач ИмяФайла, Знач ЦелевойПуть)
	Если ЯДиск = Неопределено Тогда
		
		ЯДиск = Новый ЯндексДиск;
		ЯДиск.УстановитьТокенАвторизации(OAuth_Токен);
	КонецЕсли;
	
	СвойстваДиска = ЯДиск.ПолучитьСвойстваДиска();
	Лог.Отладка("Всего доступно %1 байт", СвойстваДиска.total_space);
	Лог.Отладка("Из них занято %1 байт", СвойстваДиска.used_space);
	
	СвободноМеста = СвойстваДиска.total_space - СвойстваДиска.used_space;
	ИсходныйФайл = Новый Файл(Каталог + "\" + ИмяФайла);
	
	Если СвободноМеста < ИсходныйФайл.Размер() Тогда
		Лог.Ошибка("Недостаточно места на ЯДиске для копирования файла %1: есть %2, надо %3", ИсходныйФайл.Имя, СвободноМеста,ИсходныйФайл.Размер());
		Возврат Ложь;
	КонецЕсли;
	
	Попытка
		ЯДиск.ЗагрузитьНаДиск(ИсходныйФайл.ПолноеИмя,	ЦелевойПуть);
		Лог.Информация("Файл загружен %1", ИсходныйФайл.Имя);
	Исключение
		Лог.Ошибка("Ошибка загрузки файла %1: %2", ИсходныйФайл.Имя, ИнформацияОбОшибке());
	КонецПопытки;

	Попытка
		СвойстваФайла = ЯДиск.ПолучитьСвойстваРесурса(ЦелевойПуть + "\" + ИсходныйФайл.Имя);
	Исключение
		Лог.Ошибка("Ошибка при получении свойств файла: %1", ИнформацияОбОшибке());
	КонецПопытки;
	
	Если УдалитьИсточник Тогда
		УдалитьФайлы(ИсходныйФайл.ПолноеИмя);
		Лог.Информация("Исходный файл %1 удален", ИсходныйФайл.ПолноеИмя);
	КонецЕсли;
	
	Возврат Истина;
КонецФункции // ОтправитьФайлНаЯДиск()

// Создает папку на Я-Диске
//
// Параметры:
//  ЯДиск  - <ЯндексДиск> - <описание параметра>
//  ЦелевойПуть  - <Строка> - 
//
// Возвращаемое значение:
//   <Строка>   - Созданный путь
//
Функция СоздатьПапкуНаЯДиске(ЯДиск = Неопределено, Знач ЦелевойПуть)
	Если ЯДиск = Неопределено Тогда
		ЯДиск = Новый ЯндексДиск;
		ЯДиск.УстановитьТокенАвторизации(OAuth_Токен);
	КонецЕсли;
	
	ТекущийПуть = "";
	Попытка
		ЯДиск.СоздатьПапку(ЦелевойПуть);
	Исключение
		Лог.Ошибка("Ошибка при создании папки %1: %2", ЦелевойПуть, ИнформацияОбОшибке());
	КонецПопытки;
	
	Возврат ТекущийПуть;
КонецФункции // СоздатьПапкуНаЯДиске()

Лог = Логирование.ПолучитьЛог("ktb.app.copydb");